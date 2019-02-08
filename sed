

NOTE: SED

If you have a forward slash (/) in the variable then use different separator like below

example:
var="http://abc.com

sed "s|$var|r_str|g" file_name >new_file    / This works like a charm ...

