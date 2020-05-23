-- match rows: run/unit/cycle id, count, sha1

CREATE TABLE multiplicity(
    value CHARACTER(20) NOT NULL PRIMARY KEY,
    count INTEGER       NOT NULL);

CREATE INDEX multiplicity_by_count ON multiplicity(count);

CREATE TABLE samples(
    id        INTEGER       NOT NULL,
    count     INTEGER       NOT NULL,
    value     CHARACTER(20) NOT NULL,
    is_inject BOOLEAN       NOT NULL,
    mult      INTEGER       NOT NULL,
    verified  BOOLEAN,
    PRIMARY KEY (id ASC, count ASC));

CREATE UNIQUE INDEX samples_mult ON samples(value, mult);
CREATE UNIQUE INDEX samples_mult_value ON samples(mult, value) WHERE mult > 1;
CREATE INDEX samples_verified ON samples(verified,id,count) WHERE verified IS NOT NULL;

CREATE TABLE hits(
    id      INTEGER       NOT NULL,
    count   INTEGER       NOT NULL,
    preceed INTEGER       NOT NULL,
    value   CHARACTER(20) NOT NULL,
    image   CHARACTER(44) NOT NULL,
    PRIMARY KEY(id ASC, count ASC),
    FOREIGN KEY(id, count) REFERENCES samples)

CREATE INDEX hits_value ON hits(value);
CREATE INDEX hits_image ON hits(image);

CREATE TABLE misc(key TEXT PRIMARY KEY, value INTEGER);

CREATE TABLE prior(value CHARACTER(20) PRIMARY KEY,
                   prior CHARACTER(20),
                   image CHARACTER(40));
CREATE INDEX prior_image ON prior(image);
