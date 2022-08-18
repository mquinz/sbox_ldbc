
# LDBC SF-1 Bulk Ingestion Scripts

## Overview

These steps should be used for the bulk ingestion of LDBC-SF* data files.  They have been tested using the SF-1 set of files, but theoretically, the SF-10 and SF-100 files should be different only in the number of nodes and edges.

The basis of this work is the LDBC GitHub repo at https://github.com/ldbc/ldbc_snb_interactive_impls  

The LDBC scripts and data files on this repo were used as a starting point, but after careful analysis of the data model, it was decided to make minor tweaks to the data model to remove some obvious supernodes and to make it significantly more performant.  Unlike RDBMS rule-based data modeling processes that were codified decades ago, Neo4j's process is very flexible and architects can choose from multiple approaches in order to achieve optimal performance for the particular use case.

For example, simply eliminating the superfluous relationships (:Post)-[:IS_LOCATED_IN]->(:Country) and (:Comment)-[:IS_LOCATED_IN]->(:Country) will eliminate the need for potentially billions of unnecessary relationships - most of which would have been attached to only a handful of supernodes.  Storing a well-known Country abreviation e.g. 'UK', 'USA', 'DK' as a property on the :Post node instead of using a relationship to the :Country record is arguably a violation of the RDBMS Normalization rules, but is an expedient choice in Neo4j Graph modeling.

## Original Data model

![original Model](Neo4j-LDBC-SNB-data-model.jpeg "Original Model")

## Revised Data model

![Revised Model](LDBC_revised_model.png "Revised Model")


# Input Data File Preparation

The input files used were from the LDBC SNB SF-1 collection.  The files were unzipped into a holding directory before being prepared.
The files contain headers which are useful for using the simple LOAD CSV command, but will interfere with Neo4j-Admin import unless the utility is directed to skip the headers in the file chunks.

``` Text
--auto-skip-subsequent-headers[=<true/false>]]

```

## Neo4j Bulk Import Utility

The Neo4j bulk importer is a utility that generates a new, off-line database using specifically formattted csv files.  The data directory for the new database must be empty or the utility will throw an error message.  This means that the utility is best used for initial loads or for PoC purposes - not for incremental loading of a production database.

Please review the documentation for the bulk loading tool before attempting to run.

https://neo4j.com/docs/operations-manual/current/tutorial/neo4j-admin-import/


### Processing

The utility will first import nodes and then relationships. Specialized header files are used to specify which fields are to be imported along with their data types.  Labels can be assigned to all rows within a given CSV file and/or each row in the CSV files can specify which labels are to be assigned to that particular row.   The LDBC data files use each of these methods for assigning labels.

 ### Use of Regex.
 The admin import tool is somewhat flexible for specifying which CSV files are to be included for each --nodes or --relationships directive.  Single files may be used, Header files may be used, and Regex may be used to specify all files that meet a particular pattern.  

 Regex is fairly handy even for small imports such as the SF1 files, but is absolutely necessary for larger collections.  In the SF1 collection, there are 17 CSV Files for :Comment nodes that need to be loaded and the regex pattern $NEO4J_IMPORT_ROOT/nodes/comment.*  will automatically pull in all 17 of the file chunks. In the SF10 and SF100 collections, there can be hundreds of files for a given --nodes or --relationships directive.  

 In the snippet below, the Organization nodes will be loaded using a header file and a single CSV file.   The header file contains a column called :LABEL that specifies the contents of that column will determine which labels should be used for that row.

``` Text

--nodes=Organization=$NEO4J_IMPORT_ROOT/headers/Organization_header.csv,$NEO4J_IMPORT_ROOT/nodes/organization.csv  \

```
Organization_header.csv
``` text
id:ID(Organization)|:LABEL|name:STRING|url:STRING

```

For nodes and relationships with multiple files, the syntax is similar, but uses regex to specify the matching pattern.  The snippet below shows how the :Comment nodes are defined.

Unlike the Organization nodes   The Comment header file does not contain a column called :LABEL so the --nodes directive declares that all nodes in the file will be given a :Comment label and a :Message label.

All files that match the regex pattern will be used.   

The import utility will report back which files were used for each label directive.  This list should be carefully examined to ensure that the regex patterns were correct and that all files were processed correctly.

It is highly recommended that each of the nodes & relationships be given their own directories for containing the file chunks.   The SF1 download creates separate directories but they were not used in this script.

``` Text
nodes=Comment:Message=$NEO4J_IMPORT_ROOT/headers/Comment_header.csv,$NEO4J_IMPORT_ROOT/nodes/comment.*  \

```
Comment_header.csv
``` text
creationDate:DATETIME|id:ID(Comment)|locationIP:STRING|browserUsed:STRING|content:STRING|length:LONG

```

## Loading Syntax

```Text

../bin/neo4j-admin import \
    --database=neo4j \
    --id-type=INTEGER \
    --ignore-empty-strings=true \
    --bad-tolerance=0 \
    --auto-skip-subsequent-headers=true \
    --skip-duplicate-nodes \
    --delimiter '|' \
    --nodes $NEO4J_IMPORT_ROOT/headers/Place_header.csv,$NEO4J_IMPORT_ROOT/nodes/place.csv  \
    --nodes=Person=$NEO4J_IMPORT_ROOT/headers/Person_header.csv,$NEO4J_IMPORT_ROOT/nodes/person.*  \
    --nodes=Comment:Message=$NEO4J_IMPORT_ROOT/headers/Comment_header.csv,$NEO4J_IMPORT_ROOT/nodes/part-00000-613d6e5a-642d-46c0-8d46-842b7463cbe3.*  \
    --nodes=Organization=$NEO4J_IMPORT_ROOT/headers/Organization_header.csv,$NEO4J_IMPORT_ROOT/nodes/organization.csv  \
    --nodes=Tag=$NEO4J_IMPORT_ROOT/headers/Tag_header.csv,$NEO4J_IMPORT_ROOT/nodes/tag.csv  \
    --nodes=TagClass=$NEO4J_IMPORT_ROOT/headers/TagClass_header.csv,$NEO4J_IMPORT_ROOT/nodes/tagClass.csv  \
    --nodes=Forum=$NEO4J_IMPORT_ROOT/headers/Forum_header.csv,$NEO4J_IMPORT_ROOT/nodes/forum.csv \
    --nodes=Post:Message=$NEO4J_IMPORT_ROOT/headers/Post_header.csv,$NEO4J_IMPORT_ROOT/nodes/post.*.csv \
    --relationships=IN=$NEO4J_IMPORT_ROOT/headers/Place_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Place_IN.csv \
    --relationships=LOCATED_IN=$NEO4J_IMPORT_ROOT/headers/Person_LOCATED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_LOCATED_IN.csv \
    --relationships=WORKS_AT=$NEO4J_IMPORT_ROOT/headers/Person_WORKS_AT_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_WORKS_AT.csv \
    --relationships=STUDY_AT=$NEO4J_IMPORT_ROOT/headers/Person_STUDY_AT_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_STUDY_AT.csv \
    --relationships=INTERESTED_IN=$NEO4J_IMPORT_ROOT/headers/Person_INTERESTED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_INTERESTED_IN.csv \
    --relationships=LIKES_POST=$NEO4J_IMPORT_ROOT/headers/Person_LIKES_POST_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_LIKES_POST.csv \
    --relationships=LIKES_COMMENT=$NEO4J_IMPORT_ROOT/headers/Person_LIKES_COMMENT_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_LIKES_COMMENT.csv \
    --relationships=HAS_CREATOR=$NEO4J_IMPORT_ROOT/headers/Comment_HAS_CREATOR_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_HAS_CREATOR.*.csv \
    --relationships=REPLY_OF=$NEO4J_IMPORT_ROOT/headers/Comment_REPLY_OF_Comment_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_REPLY_OF_Comment.*.csv \
    --relationships=HAS_CREATOR=$NEO4J_IMPORT_ROOT/headers/Post_HAS_CREATOR_header.csv,$NEO4J_IMPORT_ROOT/relationships/Post_HAS_CREATOR.*.csv \
    --relationships=HAS_TAG=$NEO4J_IMPORT_ROOT/headers/Post_HAS_TAG_header.csv,$NEO4J_IMPORT_ROOT/relationships/Post_HAS_TAG.*.csv \

    --relationships=IS_LOCATED_IN=$NEO4J_IMPORT_ROOT/headers/Post_LOCATED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Post_LOCATED_IN.*.csv \


    --relationships=HAS_TAG=$NEO4J_IMPORT_ROOT/headers/Comment_HAS_TAG_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_HAS_TAG.*.csv \

    --relationships=IS_LOCATED_IN=$NEO4J_IMPORT_ROOT/headers/Comment_LOCATED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_LOCATED_IN.*.csv \

    --relationships=KNOWS=$NEO4J_IMPORT_ROOT/headers/Person_KNOWS_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_KNOWS.csv \
    --relationships=HAS_MEMBER=$NEO4J_IMPORT_ROOT/headers/Forum_HAS_MEMBER_header.csv,$NEO4J_IMPORT_ROOT/relationships/Forum_HAS_MEMBER_.* \
    --relationships=HAS_MODERATOR=$NEO4J_IMPORT_ROOT/headers/Forum_HAS_MODERATOR_header.csv,$NEO4J_IMPORT_ROOT/relationships/Forum_HAS_MODERATOR.csv \
    --relationships=CONTAINS=$NEO4J_IMPORT_ROOT/headers/Forum_CONTAINS_header.csv,$NEO4J_IMPORT_ROOT/relationships/Forum_CONTAINS.*.csv \
    --relationships=IN=$NEO4J_IMPORT_ROOT/headers/Tag_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Tag_IN.csv \
    --relationships=IN=$NEO4J_IMPORT_ROOT/headers/TagClass_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/TagClass_IN.csv

```
## Output

put output from latest import here
``` Text

```

# Mounting the database

Once the Neo4j-admin command has completed, the data directory contains a database that is ready to be mounted.
This is a simple Cypher command that can be run from either Cypher-shell, or from the Neo4j browser.

``` cypher

CREATE DATABASE name [IF NOT EXISTS]

```

It may take a few seconds - or longer for Neo to mount the DB because it's doing some consistency checks.  

You can check on the status by running the following Cypher command.

``` cypher

SHOW DATABASES

```


# Creating Indices

Once the database files have been created and mounted, the DB should be running and available for queries.  Unfortunately, virtually any query will perform poorly without first creating some indices.

Indices are created using Cypher commands and can be run using either Cypher Shell from the command line or from the Neo4j browser.

Here are the initial set of indices.  We will likely be adding some indices to support certain queries.

#### Running Cypher Shell from the command line.
``` BASH
cat indices.cypher | ../bin/cypher-shell -u username -p password --format plain

```

#### Indexing Cypher Statements
These can be run from the browser or put into a text file and run via Cypher Shell.

Generally speaking, any field used as a primary key or as a common lookup field should have an index.  Primary keys are usually defined as constraints and have supporting indexes created automatically.   All of the Labels in the LDBC model use a proprietary Id field as a primary key, so these will use constrains.  Other commonly used fields and relationships will have more traditional indices created.

Some relationship indices will be created to run common queries such as: what topics are trending based on the most recent 10k messages?
For more info on relationship indexes, please read the following.
https://neo4j.com/developer-blog/neo4j-4-3-blog-series-relationship-indexes/

``` cypher

// create primary key constraints (creates index automatically)

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

```

# Loading Results from  apoc.meta.stats

todo-update
##
``` JSON


```



# Recommended queries

# *****  In Progress **********

# Queries

## extra query - Multi-hop to find replies to replies of a Post.

Find the replies to a Post, and all of the replies to those replies - up to 5 levels deep.  Returns the paths of all the replies.

``` text
:param messageId => 824634421209

match p=(post:Post {id: $messageId })<-[:REPLY_TO_POST]-(:Comment)<-[:REPLY_TO_COMMENT*0..5]-(:Comment)
return p
```

## extra query -Counting Tags for LIKES
Find the Tags for all LIKES for comments during a particular timeframe.

``` Cypher
// 10 most popular tags for a given date range
profile MATCH ()-[r:LIKES]->(m:Message)
WHERE datetime({year: 2012, month: 11, day:01}) <= r.creationDate <= datetime({year: 2012, month: 11, day:30})
with c
match (c)-[:HAS_TAG]->(t)
with t.name as tag, count(t) as count
return tag, count order by count desc limit 10
```


## extra query - Trending Tags
Find the Tags for all LIKES for comments during a particular timeframe.

``` Cypher

// Trending Tags -10 most popular tags from the last 1000 LIKES
profile MATCH ()-[r:LIKES]->(m:Message)
where exists(r.creationDate)
with m order by r.creationDate  desc limit 1000
match (m)-[:HAS_TAG]->(t)
with (t.name) as tagName, count (m) as count
return tagName, count order by count desc limit 10

```




## Query i_short_1

## Description
For a given :Person.id, find the person and return some properties

### Status
tested successfully on SF1

### Results
Started streaming 1 records after 1 ms and completed after 1 ms.

### Optimized Cypher

``` text
// set the parameter
:params
{
  "personId": 24189255814529
}

MATCH (n:Person {id:$personId})-[:LOCATED_IN]->(p)
      RETURN
        n.firstName AS firstName,
        n.lastName AS lastName,
        n.birthday AS birthday,
        n.locationIP AS locationIP,
        n.browserUsed AS browserUsed,
        p.id AS cityId,
        n.gender AS gender,
        n.creationDate AS creationDate
```
`

## i_short_2
10 most recent posts and replies to those posts - and to those replies - up to 3 levels down

### Description
For a given :Person.id, find the person and their 10 most recent posts.  Find all replies to those posts and replies to those replies - up to 3 levels deep

### Status
tested successfully on SF1

### Results
Started streaming 10 records after 23 ms and completed after 26 ms.

``` Cypher
:params
{
  "personId": 24189255814529
}

// i_short_2

MATCH (:Person {id:$personId})<-[:HAS_CREATOR]->(message:Post)
      WITH
       message,
       message.id AS messageId,
       message.creationDate AS messageCreationDate
      ORDER BY messageCreationDate DESC, messageId ASC
      LIMIT 10
      // get replies to those posts
      MATCH (message)<-[:REPLY_OF*0..]-(reply),
            (reply)-[:HAS_CREATOR]->(person)

      RETURN
       messageId,
       messageCreationDate,
       coalesce(message.imageFile,message.content) AS messageContent,
       reply.id AS replyId,
       person.id AS personId,
       person.firstName AS personFirstName,
       person.lastName AS personLastName
      ORDER BY messageCreationDate DESC, messageId ASC

```


## i_short_3
10 Most Recent Friends


### Description
For a given :Person.id, find the person and the 10 :Persons with the most recent :KNOWS relationships.

### Status
tested successfully on SF1
### Results
Started streaming 7 records after 1 ms and completed after 3 ms.

``` Cypher
:params
{
  "personId": 24189255814529
}
// i_short_3
// 10 most recent friends
MATCH (n:Person {id:$personId})-[r:KNOWS]-(friend)
      RETURN
        friend.id AS personId,
        friend.firstName AS firstName,
        friend.lastName AS lastName,
        r.creationDate AS friendshipCreationDate
      ORDER BY friendshipCreationDate DESC, personId ASC

```


## i_short_4
Get Message by Id

### Description
For a given :Message.id, find the message and return some properties.

### Status
tested successfully on SF1
### Results
Started streaming 1 records in less than 1 ms and completed after 517 ms.

``` Cypher

// IS4. Content of a message
/*
:param messageId: 206158431836
 */
MATCH (m:Message {id:  $messageId })
RETURN
    m.creationDate as messageCreationDate,
    coalesce(m.content, m.imageFile) as messageContent


```



## i_short_5
Get Message by Id

### Description
For a given :Message.id, retrieve the name of the creator.
### Status
tested successfully on SF1
### Results
Started streaming 1 records in less than 1 ms and completed after 478 ms.

### Optimized Cypher
``` Cypher


/*
:param messageId: 206158431836
 */

 // note:  this forces the parameter to be treated as a long integer instead of as a float.

WITH toInteger($messageId) as msgId
MATCH (m:Message {id:msgId})-[:HAS_CREATOR]->(p)
        RETURN
          p.id AS personId,
          p.firstName AS firstName,
          p.lastName AS lastName
```


## i_short_6
Get the name of the :Forum and :Moderator for the parent :Post given the id of a comment.

### Description
For a given :Comment.id, traverse a recursive relationship find the parent :Post.  Then retrieve the name of the :Forum the :Post belongs to and the name of the moderator.  

### Status
tested successfully on SF1

### Results
Started streaming 1 records after 1 ms and completed after 8 ms.

### Optimized Cypher
``` Cypher


/*
:param messageId: 206158431836
 */

 // note:  this forces the parameter to be treated as a long integer instead of as a float.

 WITH toInteger($messageId) as msgId
 MATCH (m:Comment {id:msgId})-[:REPLY_OF*0..]->(p:Post)<-[:CONTAINS]-(f)-[:HAS_MODERATOR]->(mod)
       RETURN
         f.id AS forumId,
         f.title AS forumTitle,
         mod.id AS moderatorId,
         mod.firstName AS moderatorFirstName,
         mod.lastName AS moderatorLastName
         LIMIT 1
```


## i_short_7
Get the name of persons that reply to a comment - and indicate if the original author knows each person making a response.

### Description
For a given :Message.id (either a :Post or :Comment) get the names of all persons replying to that message and deterimine if the person knows the author.

### Status
tested successfully on SF1

### Results
Started streaming 3 records after 1 ms and completed after 505 ms.

### Optimized Cypher
``` Cypher


/*
:param messageId: 824633721393
 */

 // note:  this forces the parameter to be treated as a long integer instead of as a float.

 WITH toInteger($messageId) as msgId
 MATCH (author)<-[:HAS_CREATOR]-(message:Message {id:msgId}),
        (message)<-[:REPLY_OF]-(reply),
        (reply)-[:HAS_CREATOR]->(replyAuthor)
        RETURN
         replyAuthor.id AS replyAuthorId,
         replyAuthor.firstName AS replyAuthorFirstName,
         replyAuthor.lastName AS replyAuthorLastName,
         reply.id AS commentId,
         reply.content AS commentContent,
         reply.creationDate AS commentCreationDate,
         exists((author)-[:KNOWS]-(replyAuthor)) AS replyAuthorKnowsOriginalMessageAuthor
        ORDER BY commentCreationDate DESC, replyAuthorId ASC
```



# Complex Queries

## Query i_complex_1
Find closest friends with same first name


### Description
A person may have many friends with the same first name. This query finds the 20 closest - in terms of number of hops - and then obtains some details for them.

### Status
tested successfully on SF1

### Results
Started streaming 20 records after 1 ms and completed after 240 ms.

### Optimized Cypher

``` text
// set the parameters
:params
{
  "p1Id": 26388279067642,
  "firstName": "John"
}

MATCH (p:Person {id:$p1Id}), (friend:Person {firstName:$firstName})
       WITH p, friend
       MATCH path = shortestPath((p)-[:KNOWS*1..3]-(friend))
       WITH min(length(path)) AS distance, friend
       ORDER BY distance ASC, friend.lastName ASC, toInteger(friend.id) ASC
       LIMIT 20
       MATCH (friend)-[:LOCATED_IN]->(friendCity)
       OPTIONAL MATCH (friend)-[studyAt:STUDY_AT]->(uni)-[:LOCATED_IN]->(uniCity)
       WITH
         friend,
         collect(
           CASE uni.name
             WHEN null THEN null
             ELSE [uni.name, studyAt.classYear, uniCity.name]
           END
         ) AS unis,
         friendCity,
         distance
       OPTIONAL MATCH (friend)-[workAt:WORKS_AT]->(company)-[:LOCATED_IN]->(companyCountry)
       WITH
         friend,
         collect(
           CASE company.name
             WHEN null THEN null
             ELSE [company.name, workAt.workFrom, companyCountry.name]
           END
         ) AS companies,
         unis,
         friendCity,
         distance
       RETURN
         friend.id AS friendId,
         friend.lastName AS friendLastName,
         distance AS distanceFromPerson,
         friend.birthday AS friendBirthday,
         friend.creationDate AS friendCreationDate,
         friend.gender AS friendGender,
         friend.browserUsed AS friendBrowserUsed,
         friend.locationIP AS friendLocationIp,
         friend.email AS friendEmails,
         friend.speaks AS friendLanguages,
         friendCity.name AS friendCityName,
         unis AS friendUniversities,
         companies AS friendCompanies
       ORDER BY distanceFromPerson ASC, friendLastName ASC, friendId ASC
       LIMIT 20
```


## Query i_complex_2
Find closest friends with same first name


### Description
Get the 20 most recent messages from :Persons that know a given person where the messages are also before a given date

### Status
tested successfully on SF1

### Results
Started streaming 20 records after 1 ms and completed after 226 ms.

### Optimized Cypher

``` text
// set the parameters
:params
{
  "personId": 26388279067642,
  "month":11,
  "day":30,
  "year":2012
}

WITH toInteger($personId) as pId, datetime({year: toInteger($year), month: toInteger($month), day: toInteger($day)}) AS maxDate

MATCH (:Person {id:pId})-[:KNOWS]-(friend)<-[:HAS_CREATOR]-(message)
       WHERE message.creationDate <= maxDate
       RETURN
         friend.id AS personId,
         friend.firstName AS personFirstName,
         friend.lastName AS personLastName,
         message.id AS messageId,
         COALESCE(message.content, message.imageFile) AS messageContent,
         message.creationDate AS messageCreationDate
       ORDER BY messageCreationDate DESC, messageId ASC
       LIMIT 20
```

## Query i_complex_3
Find closest friends with same first name


### Description

### Status
tested successfully on SF1

### Results
Started streaming 20 records after 1 ms and completed after 226 ms.

### Optimized Cypher

``` text
// set the parameters
:params
{
  "personId": 26388279067642,
  "month":11,
  "day":30,
  "year":2012
}

WITH toInteger($personId) as pId, datetime({year: toInteger($year), month: toInteger($month), day: toInteger($day)}) AS maxDate

MATCH (:Person {id:pId})-[:KNOWS]-(friend)<-[:HAS_CREATOR]-(message)
       WHERE message.creationDate <= maxDate
       RETURN
         friend.id AS personId,
         friend.firstName AS personFirstName,
         friend.lastName AS personLastName,
         message.id AS messageId,
         COALESCE(message.content, message.imageFile) AS messageContent,
         message.creationDate AS messageCreationDate
       ORDER BY messageCreationDate DESC, messageId ASC
       LIMIT 20
```
