# Standard LDBC Queries


## Query i_short_1

### Description
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

# Additional Queries
These are some useful queries that were used to demonstrate some features to an internal team.  They are NOT part of the LDBC package.

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
