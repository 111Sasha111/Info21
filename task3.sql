-- Функция: возвращает TransferredPoints в удобочитаемом виде
CREATE OR REPLACE FUNCTION fnc_transferred_points()
RETURNS TABLE (Peer1 VARCHAR, Peer2 VARCHAR, PointsAmount INT) AS $$
BEGIN
    RETURN QUERY
    SELECT tp.CheckingPeer AS Peer1,
           tp.CheckedPeer AS Peer2,
           tp.PointsAmount
    FROM TransferredPoints tp;
END;
$$ LANGUAGE plpgsql;

-- Функция: возвращает таблицу (username, task, xp)
CREATE OR REPLACE FUNCTION fnc_successful_tasks_xp()
RETURNS TABLE (Peer VARCHAR, Task VARCHAR, XP INT) AS $$
BEGIN
    RETURN QUERY
    SELECT c.Peer, c.Task, x.XPAmount
    FROM XP x
    JOIN Checks c ON x.CheckID = c.ID;
END;
$$ LANGUAGE plpgsql;

-- Функция: возвращает пиров, не покидавших кампус весь день
CREATE OR REPLACE FUNCTION fnc_peers_never_left(p_date DATE)
RETURNS TABLE (Peer VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT t1.Peer
    FROM TimeTracking t1
    WHERE t1.Date = p_date AND t1.State = 1
      AND NOT EXISTS (
          SELECT 1 FROM TimeTracking t2
          WHERE t2.Peer = t1.Peer
            AND t2.Date = p_date
            AND t2.State = 2
            AND t2.Time > t1.Time
      );
END;
$$ LANGUAGE plpgsql;

-- Функция: изменение количества очков каждого пира
CREATE OR REPLACE FUNCTION fnc_points_change()
RETURNS TABLE (Peer VARCHAR, PointsChange BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH points_given AS (
        SELECT CheckingPeer AS Peer, SUM(PointsAmount) AS Total
        FROM TransferredPoints
        GROUP BY CheckingPeer
    ),
    points_received AS (
        SELECT CheckedPeer AS Peer, SUM(PointsAmount) AS Total
        FROM TransferredPoints
        GROUP BY CheckedPeer
    )
    SELECT COALESCE(g.Peer, r.Peer) AS Peer,
           (COALESCE(r.Total, 0) - COALESCE(g.Total, 0)) AS PointsChange
    FROM points_given g
    FULL OUTER JOIN points_received r ON g.Peer = r.Peer
    ORDER BY PointsChange DESC;
END;
$$ LANGUAGE plpgsql;
