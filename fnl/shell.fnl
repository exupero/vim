(fn escape-single-quotes [s]
  (string.gsub s "'" "'\"'\"'"))

(fn escape-double-quotes [s]
  (string.gsub s "\"" "\\\""))

{: escape-single-quotes
 : escape-double-quotes}
