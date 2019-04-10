

NOTE: SED
If you have a forward slash (/) in the variable then use different separator like below

example:
var="http://abc.com
sed "s|$var|r_str|g" file_name >new_file    / This works like a charm ...

URL REFS:
https://unix.stackexchange.com/questions/69112/how-can-i-use-variables-in-the-lhs-and-rhs-of-a-sed-substitution


