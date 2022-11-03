arch=$(uname -m)
if [[ $arch == x86_64* ]]; then
    echo "X64 Architecture"
    wget -O /tmp/zulujdk.tar.gz https://cdn.azul.com/zulu/bin/zulu8.66.0.15-ca-fx-jdk8.0.352-linux_x64.tar.gz
    tar --extract --file /tmp/zulujdk.tar.gz --directory "$JAVA_HOME" --strip-components 1
elif  [[ $arch == arm* ]] || [[ $arch = aarch64 ]]; then
    echo "ARM Architecture"
    wget -O /tmp/zulujdk.tar.gz https://cdn.azul.com/zulu-embedded/bin/zulu8.66.0.15-ca-jdk8.0.352-linux_aarch64.tar.gz
    tar --extract --file /tmp/zulujdk.tar.gz --directory "$JAVA_HOME" --strip-components 1
    apt-get install -y openjfx
fi
