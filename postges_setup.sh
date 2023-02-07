## setup postgres13 and common extensions https://www.postgresql.org/docs/current/contrib.html
su - root -c "yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
su - root -c "yum install -y postgresql13 postgresql13-contrib"

