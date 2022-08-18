


echo "==============================================================================="
echo "Indexing the Neo4j database"
echo "-------------------------------------------------------------------------------"

cat indices.cypher | ../bin/cypher-shell -u neo4j -p admin --format plain
