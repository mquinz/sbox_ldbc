
CREATE CONSTRAINT organization_constraint
IF NOT EXISTS
FOR (n:Organization) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT place_constraint
IF NOT EXISTS
FOR (n:Place) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT tag_constraint
IF NOT EXISTS
FOR (n:Tag) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT tagclass_constraint
IF NOT EXISTS
FOR (n:TagClass) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT person_constraint
IF NOT EXISTS
FOR (n:Person) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT post_constraint
IF NOT EXISTS
FOR (n:Post) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT forum_constraint
IF NOT EXISTS
FOR (n:Forum) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT comment_constraint
IF NOT EXISTS
FOR (n:Comment) REQUIRE n.id IS UNIQUE;

// creationDate Index
CREATE INDEX Message_Index IF NOT EXISTS FOR (n:Message) ON (n.creationDate);
CREATE INDEX Comment_Index IF NOT EXISTS FOR (n:Comment) ON (n.creationDate);
CREATE INDEX Post_Index IF NOT EXISTS FOR (n:Post) ON (n.creationDate);
CREATE INDEX Forum_Index IF NOT EXISTS FOR (n:Forum) ON (n.creationDate);
CREATE INDEX Person_Index IF NOT EXISTS FOR (n:Person) ON (n.creationDate);


// Name Index
CREATE INDEX Country_Index IF NOT EXISTS FOR (n:Country) ON (n.name);
CREATE INDEX Tag_Index IF NOT EXISTS FOR (n:Tag) ON (n.name);
CREATE INDEX TagClass_Index IF NOT EXISTS FOR (n:TagClass) ON (n.name);
CREATE INDEX Organization_Index IF NOT EXISTS FOR (n:Organization) ON (n.name);
CREATE INDEX Company_Index IF NOT EXISTS FOR (n:Company) ON (n.name);

CREATE INDEX node_index_firstname IF NOT EXISTS FOR (n:Person) ON (n.firstName);

// NOTE: This is a composite INDEX
// and the LDBC version uses only first name!
CREATE INDEX node_index_name IF NOT EXISTS FOR (n:Person) ON (n.firstName, n.lastName);

// Sample Relationship INDEX
CREATE INDEX likesIndex IF NOT EXISTS FOR ()-[r:LIKES]-() ON (r.creationDate);
