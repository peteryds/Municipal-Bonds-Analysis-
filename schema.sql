-- ============================================================
-- MUNICIPAL BONDS DATABASE — FINAL NORMALIZED SCHEMA (3NF)
-- ============================================================


-- ==============================
-- 1. ISSUERS
-- ==============================
DROP TABLE IF EXISTS issuers CASCADE;

CREATE TABLE issuers (
    issuer_id          INTEGER PRIMARY KEY,
    issuer_name        TEXT NOT NULL,
    state              CHAR(2) NOT NULL,
    issuer_type        TEXT,
    population         NUMERIC,
    tax_base_millions  NUMERIC,

    CONSTRAINT chk_issuer_state CHECK (char_length(state) = 2),
    CONSTRAINT chk_issuer_population CHECK (population IS NULL OR population >= 0),
    CONSTRAINT chk_tax_base CHECK (tax_base_millions IS NULL OR tax_base_millions >= 0)
);

CREATE INDEX idx_issuers_state ON issuers(state);



-- ==============================
-- 2. BOND PURPOSES
-- ==============================
DROP TABLE IF EXISTS bond_purposes CASCADE;

CREATE TABLE bond_purposes (
    purpose_id          INTEGER PRIMARY KEY,
    purpose_category    TEXT NOT NULL,
    purpose_description TEXT,
    
    CONSTRAINT uq_purpose_category UNIQUE (purpose_category)
);



-- ==============================
-- 3. BONDS
-- ==============================
DROP TABLE IF EXISTS bonds CASCADE;

CREATE TABLE bonds (
    bond_id        VARCHAR(20) PRIMARY KEY,
    issuer_id      INTEGER NOT NULL,
    purpose_id     INTEGER NOT NULL,
    cusip          TEXT NOT NULL,
    bond_type      TEXT NOT NULL,
    coupon_rate    NUMERIC NOT NULL,
    issue_date     DATE NOT NULL,
    maturity_date  DATE NOT NULL,
    face_value     NUMERIC NOT NULL,
    duration       NUMERIC,
    tax_status     TEXT,

    CONSTRAINT fk_bonds_issuer
        FOREIGN KEY (issuer_id)
        REFERENCES issuers(issuer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_bonds_purpose
        FOREIGN KEY (purpose_id)
        REFERENCES bond_purposes(purpose_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_coupon CHECK (coupon_rate >= 0),
    CONSTRAINT chk_face_value CHECK (face_value > 0),
    CONSTRAINT chk_duration CHECK (duration IS NULL OR duration >= 0),
    CONSTRAINT chk_maturity CHECK (maturity_date > issue_date)
);

CREATE INDEX idx_bonds_issuer  ON bonds(issuer_id);
CREATE INDEX idx_bonds_purpose ON bonds(purpose_id);
CREATE INDEX idx_bonds_cusip   ON bonds(cusip);



-- ==============================
-- 4. CREDIT RATINGS
-- ==============================
DROP TABLE IF EXISTS credit_ratings CASCADE;

CREATE TABLE credit_ratings (
    rating_id      INTEGER PRIMARY KEY,
    bond_id        VARCHAR(20) NOT NULL,
    rating_agency  TEXT NOT NULL,
    rating         TEXT NOT NULL,
    rating_date    DATE NOT NULL,
    outlook        TEXT,

    CONSTRAINT fk_ratings_bond
        FOREIGN KEY (bond_id)
        REFERENCES bonds(bond_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT uq_rating_unique UNIQUE (bond_id, rating_agency, rating_date)
);

CREATE INDEX idx_ratings_bond_date ON credit_ratings(bond_id, rating_date);
CREATE INDEX idx_ratings_grade     ON credit_ratings(rating);



-- ==============================
-- 5. TRADES
-- ==============================
DROP TABLE IF EXISTS trades CASCADE;

CREATE TABLE trades (
    bond_id      VARCHAR(20) NOT NULL,
    trade_date   DATE NOT NULL,
    trade_price  NUMERIC NOT NULL,
    yield        NUMERIC NOT NULL,
    quantity     NUMERIC NOT NULL,
    buyer_type   TEXT,

    trade_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    CONSTRAINT fk_trades_bond
        FOREIGN KEY (bond_id)
        REFERENCES bonds(bond_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_price CHECK (trade_price > 0),
    CONSTRAINT chk_yield CHECK (yield >= 0),
    CONSTRAINT chk_quantity CHECK (quantity > 0)
);

CREATE INDEX idx_trades_bond_date ON trades(bond_id, trade_date);



-- ==============================
-- 6. ECONOMIC INDICATORS
-- ==============================
DROP TABLE IF EXISTS economic_indicators CASCADE;

CREATE TABLE economic_indicators (
    state             CHAR(2) NOT NULL,
    date              DATE NOT NULL,
    unemployment_rate NUMERIC,
    treasury_10yr     NUMERIC,
    treasury_20yr     NUMERIC,
    vix_index         NUMERIC,

    econ_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    CONSTRAINT chk_e_state CHECK (char_length(state) = 2),
    CONSTRAINT chk_unemp CHECK (unemployment_rate IS NULL OR unemployment_rate >= 0),
    CONSTRAINT chk_t10 CHECK (treasury_10yr IS NULL OR treasury_10yr >= 0),
    CONSTRAINT chk_t20 CHECK (treasury_20yr IS NULL OR treasury_20yr >= 0),
    CONSTRAINT chk_vix CHECK (vix_index IS NULL OR vix_index >= 0),

    CONSTRAINT uq_econ_state_date UNIQUE (state, date)
);

CREATE INDEX idx_econ_state_date ON economic_indicators(state, date);
