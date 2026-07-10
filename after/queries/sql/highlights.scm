; extends
; highlights.scm

(
    [
     (keyword_where)
     (keyword_select)
     (keyword_from)
     (keyword_as)
     (keyword_on)
     (keyword_with)
     (keyword_partition)
     (keyword_group)
     (keyword_by)
     (keyword_filter)
     (keyword_over)
     (keyword_order)
     (keyword_join)
     (keyword_left)
     (keyword_right)
     (keyword_cross)
     (keyword_inner)
    ]@warning.lowercase
    (#match? @warning.lowercase "^.*[a-z].*$")
)
