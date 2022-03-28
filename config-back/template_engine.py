from jinja2 import Environment, FileSystemLoader
template_engine = Environment(
    loader=FileSystemLoader("templates"), 
    variable_start_string='{{{', 
    variable_end_string='}}}',
    comment_start_string= '{##',
    comment_end_string= '##}',
    lstrip_blocks=True,
    trim_blocks=True,
)

def __ahkString(s):
    s = s.replace('"',  '""')
    return '"' + s + '"'

template_engine.filters['ahkString'] = __ahkString
