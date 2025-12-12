-- part1.sql

-- Создание перечисления для статуса проверки
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

-- Таблица пиров
CREATE TABLE Peers (
    Nickname VARCHAR(50) PRIMARY KEY,
    Birthday DATE NOT NULL
);

-- Таблица задач
CREATE TABLE Tasks (
    Title VARCHAR(50) PRIMARY KEY,
    ParentTask VARCHAR(50) REFERENCES Tasks(Title),
    MaxXP INT NOT NULL CHECK (MaxXP > 0)
);

-- Таблица проверок
CREATE TABLE Checks (
    ID SERIAL PRIMARY KEY,
    Peer VARCHAR(50) REFERENCES Peers(Nickname),
    Task VARCHAR(50) REFERENCES Tasks(Title),
    Date DATE NOT NULL
);

-- Таблица P2P-проверок
CREATE TABLE P2P (
    ID SERIAL PRIMARY KEY,
    CheckID INT REFERENCES Checks(ID),
    CheckingPeer VARCHAR(50) REFERENCES Peers(Nickname),
    State check_status NOT NULL,
    Time TIME NOT NULL
);

-- Таблица проверок Verter
CREATE TABLE Verter (
    ID SERIAL PRIMARY KEY,
    CheckID INT REFERENCES Checks(ID),
    State check_status NOT NULL,
    Time TIME NOT NULL
);

-- Таблица передачи очков
CREATE TABLE TransferredPoints (
    ID SERIAL PRIMARY KEY,
    CheckingPeer VARCHAR(50) REFERENCES Peers(Nickname),
    CheckedPeer VARCHAR(50) REFERENCES Peers(Nickname),
    PointsAmount INT NOT NULL CHECK (PointsAmount >= 0)
);

-- Таблица друзей
CREATE TABLE Friends (
    ID SERIAL PRIMARY KEY,
    Peer1 VARCHAR(50) REFERENCES Peers(Nickname),
    Peer2 VARCHAR(50) REFERENCES Peers(Nickname),
    CHECK (Peer1 != Peer2)
);

-- Таблица рекомендаций
CREATE TABLE Recommendations (
    ID SERIAL PRIMARY KEY,
    Peer VARCHAR(50) REFERENCES Peers(Nickname),
    RecommendedPeer VARCHAR(50) REFERENCES Peers(Nickname),
    CHECK (Peer != RecommendedPeer)
);

-- Таблица XP
CREATE TABLE XP (
    ID SERIAL PRIMARY KEY,
    CheckID INT REFERENCES Checks(ID),
    XPAmount INT NOT NULL CHECK (XPAmount >= 0)
);

-- Таблица посещений кампуса
CREATE TABLE TimeTracking (
    ID SERIAL PRIMARY KEY,
    Peer VARCHAR(50) REFERENCES Peers(Nickname),
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    State INT NOT NULL CHECK (State IN (1, 2)) -- 1 = вход, 2 = выход
);
