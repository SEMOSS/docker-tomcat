os=$(uname)
if [[ $os == *Windows* ]] || [[ $os == Darwin ]]; then
    echo "Case insensitive filesystem, context.xml wont be configured"
else
    echo "Updating context.xml"
    cp context.xml $TOMCAT_HOME/conf/context.xml
fi