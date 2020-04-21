-- match rows: run/unit/cycle id, count, sha1

CREATE TABLE multiplicity(
    value CHARACTER(20) NOT NULL PRIMARY KEY,
    count INTEGER NOT NULL);

CREATE INDEX multiplicity_by_count ON multiplicity(count);

CREATE TABLE samples(
    id INTEGER NOT NULL,
    count INTEGER NOT NULL,
    value CHARACTER(20) NOT NULL,
    is_inject BOOLEAN NOT NULL,
    mult INTEGER NOT NULL,
    hit BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (id ASC, count ASC));

CREATE INDEX samples_by_text ON samples(value);

CREATE INDEX samples_ordered ON samples(id ASC, count ASC);
CREATE UNIQUE INDEX samples_mult ON samples(value, mult);
CREATE INDEX sample_hits ON samples(hit);

CREATE TABLE hits(
    id INTEGER NOT NULL,
    count INTEGER NOT NULL,
    preceed INTEGER NOT NULL,
    value CHARACTER(20) NOT NULL,
    image CHARACTER(40) NOT NULL,
    PRIMARY KEY (id ASC, count ASC))

CREATE INDEX hits_value ON hits(value);
CREATE INDEX hits_image ON hits(image);
