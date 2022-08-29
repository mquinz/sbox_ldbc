
export NEO4J_ROOT=/Users/markquinsland/Library/Application\ Support/Neo4j\ Desktop/Application/relate-data/dbmss/dbms-07b4a66d-2800-426b-afb7-cc73a00f791d
echo $NEO4J_ROOT

#export NEO4J_IMPORT_ROOT=/Users/markquinsland/Library/Application\ Support/Neo4j\ Desktop/Application/relate-data/dbmss/dbms-07b4a66d-2800-426b-afb7-cc73a00f791d/import
export NEO4J_IMPORT_ROOT=/Users/markquinsland/Documents/GitHub/sbox_ldbc/import
echo $NEO4J_IMPORT_ROOT
#!/bin/bash


echo "==============================================================================="
echo "Loading the Neo4j database"
echo "-------------------------------------------------------------------------------"
echo "NEO4J_CONTAINER_ROOT: ${NEO4J_CONTAINER_ROOT}"
echo "NEO4J_VERSION: ${NEO4J_VERSION}"
echo "NEO4J_CONTAINER_NAME: ${NEO4J_CONTAINER_NAME}"
echo "NEO4J_ENV_VARS: ${NEO4J_ENV_VARS}"
echo "NEO4J_DATA_DIR (on the host machine):"
echo "  ${NEO4J_DATA_DIR}"
echo "NEO4J_CSV_DIR (on the host machine):"
echo "  ${NEO4J_CSV_DIR}"
echo "==============================================================================="

export JAVA_OPTS='-server -Xms1g -Xmx1g'
echo "JAVA_OPTS: ${JAVA_OPTS}"

# uses default database neo4j - change as appropriate

# Note - many of these use regex to allow multiple files for nodes/edges

../bin/neo4j-admin import \
    --database=neo4j \
    --id-type=INTEGER \
    --ignore-empty-strings=true \
    --bad-tolerance=0 \
    --auto-skip-subsequent-headers=true \
    --skip-duplicate-nodes \
    --delimiter '|' \
    --nodes $NEO4J_IMPORT_ROOT/headers/Place_header.csv,$NEO4J_IMPORT_ROOT/nodes/Place/place.*  \
    --nodes=Person=$NEO4J_IMPORT_ROOT/headers/Person_header.csv,$NEO4J_IMPORT_ROOT/nodes/Person/person.*  \
    --nodes=Comment:Message=$NEO4J_IMPORT_ROOT/headers/Comment_header.csv,$NEO4J_IMPORT_ROOT/nodes/Comment/comment.*  \
    --nodes=Organization=$NEO4J_IMPORT_ROOT/headers/Organization_header.csv,$NEO4J_IMPORT_ROOT/nodes/Organization/organization.*  \
    --nodes=Tag=$NEO4J_IMPORT_ROOT/headers/Tag_header.csv,$NEO4J_IMPORT_ROOT/nodes/Tag/tag.*  \
    --nodes=TagClass=$NEO4J_IMPORT_ROOT/headers/TagClass_header.csv,$NEO4J_IMPORT_ROOT/nodes/TagClass/tagClass.*  \
    --nodes=Forum=$NEO4J_IMPORT_ROOT/headers/Forum_header.csv,$NEO4J_IMPORT_ROOT/nodes/Forum/forum.* \
    --nodes=Post:Message=$NEO4J_IMPORT_ROOT/headers/Post_header.csv,$NEO4J_IMPORT_ROOT/nodes/Post/post.* \
    --relationships=IS_LOCATED_IN=$NEO4J_IMPORT_ROOT/headers/Post_LOCATED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Post_LOCATED_IN/Post_LOCATED_IN.* \
    --relationships=IS_LOCATED_IN=$NEO4J_IMPORT_ROOT/headers/Comment_LOCATED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_LOCATED_IN/Comment_LOCATED_IN.* \
    --relationships=IN=$NEO4J_IMPORT_ROOT/headers/Place_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Place_IN/Place_IN.* \
    --relationships=LOCATED_IN=$NEO4J_IMPORT_ROOT/headers/Person_LOCATED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_LOCATED_IN/Person_LOCATED_IN.* \
    --relationships=WORKS_AT=$NEO4J_IMPORT_ROOT/headers/Person_WORKS_AT_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_WORKS_AT/Person_WORKS_AT.* \
    --relationships=STUDY_AT=$NEO4J_IMPORT_ROOT/headers/Person_STUDY_AT_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_STUDY_AT/Person_STUDY_AT.csv \
    --relationships=INTERESTED_IN=$NEO4J_IMPORT_ROOT/headers/Person_INTERESTED_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_INTERESTED_IN/Person_INTERESTED_IN.csv \
    --relationships=LIKES_POST=$NEO4J_IMPORT_ROOT/headers/Person_LIKES_POST_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_LIKES_POST/Person_LIKES_POST.* \
    --relationships=LIKES_COMMENT=$NEO4J_IMPORT_ROOT/headers/Person_LIKES_COMMENT_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_LIKES_COMMENT/Person_LIKES_COMMENT.* \
    --relationships=HAS_CREATOR=$NEO4J_IMPORT_ROOT/headers/Comment_HAS_CREATOR_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_HAS_CREATOR/Comment_HAS_CREATOR.* \
    --relationships=REPLY_OF=$NEO4J_IMPORT_ROOT/headers/Comment_REPLY_OF_Comment_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_REPLY_OF_Comment/Comment_REPLY_OF_Comment.* \
    --relationships=REPLY_OF=$NEO4J_IMPORT_ROOT/headers/Comment_REPLY_OF_Post_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_REPLY_OF_Post/Comment_REPLY_OF_Post.* \
    --relationships=HAS_CREATOR=$NEO4J_IMPORT_ROOT/headers/Post_HAS_CREATOR_header.csv,$NEO4J_IMPORT_ROOT/relationships/Post_HAS_CREATOR/Post_HAS_CREATOR.* \
    --relationships=HAS_TAG=$NEO4J_IMPORT_ROOT/headers/Post_HAS_TAG_header.csv,$NEO4J_IMPORT_ROOT/relationships/Post_HAS_TAG/Post_HAS_TAG.* \
    --relationships=HAS_TAG=$NEO4J_IMPORT_ROOT/headers/Comment_HAS_TAG_header.csv,$NEO4J_IMPORT_ROOT/relationships/Comment_HAS_TAG/Comment_HAS_TAG.* \
    --relationships=KNOWS=$NEO4J_IMPORT_ROOT/headers/Person_KNOWS_header.csv,$NEO4J_IMPORT_ROOT/relationships/Person_KNOWS/Person_KNOWS.* \
    --relationships=HAS_MEMBER=$NEO4J_IMPORT_ROOT/headers/Forum_HAS_MEMBER_header.csv,$NEO4J_IMPORT_ROOT/relationships/Forum_HAS_MEMBER/Forum_HAS_MEMBER.* \
    --relationships=HAS_MODERATOR=$NEO4J_IMPORT_ROOT/headers/Forum_HAS_MODERATOR_header.csv,$NEO4J_IMPORT_ROOT/relationships/Forum_HAS_MODERATOR/Forum_HAS_MODERATOR.* \
    --relationships=CONTAINS=$NEO4J_IMPORT_ROOT/headers/Forum_CONTAINS_header.csv,$NEO4J_IMPORT_ROOT/relationships/Forum_CONTAINS/Forum_CONTAINS.*.csv \
    --relationships=IN=$NEO4J_IMPORT_ROOT/headers/Tag_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/Tag_IN/Tag_IN.*.csv \
    --relationships=IN=$NEO4J_IMPORT_ROOT/headers/TagClass_IN_header.csv,$NEO4J_IMPORT_ROOT/relationships/TagClass_IN/TagClass_IN.*.csv
