year=$(date +%Y)
mon=$(date +%m)
day=$(date +%d)
hugo new --kind post posts/${year}/${mon}${day}/$1.md