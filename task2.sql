-- Процедура для добавления P2P проверки
CREATE OR REPLACE PROCEDURE AddP2PCheck(
    p_checked_peer VARCHAR,
    p_checking_peer VARCHAR,
    p_task_title VARCHAR,
    p_check_status check_status,
    p_check_time TIME
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_id INT;
BEGIN
    -- Если статус 'Start', создаём новую запись в Checks и P2P
    IF p_check_status = 'Start' THEN
        INSERT INTO Checks (Peer, Task, Date)
        VALUES (p_checked_peer, p_task_title, CURRENT_DATE)
        RETURNING ID INTO v_check_id;

        INSERT INTO P2P (CheckID, CheckingPeer, State, Time)
        VALUES (v_check_id, p_checking_peer, p_check_status, p_check_time);
    ELSE
        -- Иначе ищем последнюю незавершённую проверку
        SELECT ID INTO v_check_id
        FROM Checks c
        JOIN P2P p ON c.ID = p.CheckID
        WHERE c.Peer = p_checked_peer
          AND c.Task = p_task_title
          AND p.CheckingPeer = p_checking_peer
          AND p.State = 'Start'
        ORDER BY p.Time DESC
        LIMIT 1;

        IF v_check_id IS NOT NULL THEN
            INSERT INTO P2P (CheckID, CheckingPeer, State, Time)
            VALUES (v_check_id, p_checking_peer, p_check_status, p_check_time);
        END IF;
    END IF;
END;
$$;

-- Процедура для добавления проверки Verter
CREATE OR REPLACE PROCEDURE AddVerterCheck(
    p_checked_peer VARCHAR,
    p_task_title VARCHAR,
    p_check_status check_status,
    p_check_time TIME
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_id INT;
BEGIN
    -- Найти последнюю успешную P2P проверку по задаче
    SELECT c.ID INTO v_check_id
    FROM Checks c
    JOIN P2P p ON c.ID = p.CheckID
    WHERE c.Peer = p_checked_peer
      AND c.Task = p_task_title
      AND p.State = 'Success'
    ORDER BY p.Time DESC
    LIMIT 1;

    IF v_check_id IS NOT NULL THEN
        INSERT INTO Verter (CheckID, State, Time)
        VALUES (v_check_id, p_check_status, p_check_time);
    END IF;
END;
$$;

-- Триггер: обновление XP только если проверка успешна и XP ≤ MaxXP
CREATE OR REPLACE FUNCTION trg_check_xp()
RETURNS TRIGGER AS $$
DECLARE
    v_max_xp INT;
BEGIN
    SELECT t.MaxXP INTO v_max_xp
    FROM XP x
    JOIN Checks c ON x.CheckID = c.ID
    JOIN Tasks t ON c.Task = t.Title
    WHERE x.ID = NEW.ID;

    IF NEW.XPAmount > v_max_xp OR
       EXISTS (
           SELECT 1 FROM Verter v
           WHERE v.CheckID = NEW.CheckID AND v.State = 'Failure'
       ) THEN
        RETURN NULL; -- Отмена вставки
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_insert_xp
BEFORE INSERT ON XP
FOR EACH ROW EXECUTE FUNCTION trg_check_xp();

-- Триггер: при добавлении P2P с State = 'Start' добавлять запись в TransferredPoints
CREATE OR REPLACE FUNCTION trg_add_transferred_points()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.State = 'Start' THEN
        INSERT INTO TransferredPoints (CheckingPeer, CheckedPeer, PointsAmount)
        VALUES (
            NEW.CheckingPeer,
            (SELECT Peer FROM Checks WHERE ID = NEW.CheckID),
            1
        )
        ON CONFLICT (CheckingPeer, CheckedPeer)
        DO UPDATE SET PointsAmount = TransferredPoints.PointsAmount + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_after_insert_p2p
AFTER INSERT ON P2P
FOR EACH ROW EXECUTE FUNCTION trg_add_transferred_points();
