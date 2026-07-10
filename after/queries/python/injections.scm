; extends
; suport cursor

(call 
    function: (attribute 
                attribute: (identifier) @_method)
    arguments: (argument_list
                  (string 
                    (string_content) @injection.content 
                  )
               )
(#eq? @_method "sql")
(#set! injection.language "sql"))

((assignment     
    left: (identifier) @ident
    right: (string (string_content) @injection.content )
) @assigment 
(#match? @ident "^.*_sql$")
(#set! injection.language "sql"))
