#!/bin/bash

_funcList() { egrep "^[a-z].*\(\) " $0 | cut -d'(' -f1 | grep -v "${FUNCNAME[0]}"; };
_funcDesc() { egrep "^[a-z].*\(\) " $0; };
funcTestA() { # desc A
  echo "${FUNCNAME[0]} executed."
};
funcTestB() { # desc B
  echo "${FUNCNAME[0]} executed."
};

#echo -e "`_funcDesc | cut -d'#' -f2`\n" # show function comment
declare -rx func_arr=($(_funcList)); # build array from script function name list

# iterate function array, exec each in the order they
# were defined.
for i in "${func_arr[@]}"; do
  eval "$i";
done
