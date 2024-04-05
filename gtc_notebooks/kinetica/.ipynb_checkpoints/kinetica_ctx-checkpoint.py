import textwrap

class KineticaContextBuilder:

    @classmethod
    def _quote_sql_obj(cls, obj: str) -> str:
        parts = obj.split(".")
        parts = [f'"{p}"' for p in parts]
        return ".".join(parts)

    def __repr__(self):
        return self.__str__()
    
    @classmethod
    def _quote_text(cls, text: str) -> str:
        text = text.replace("'", "''").strip()
        return f"'{text}'"
    
    @classmethod
    def _parens(cls, lines: list[str]) -> str:
        params_str =  ','.join(lines)
        return f"( {params_str} )"

    @classmethod
    def _quote_list(cls, items: list[str]) -> str:
        lines = [ cls._quote_text(item) for item in items]
        return cls._parens(lines)

    @classmethod
    def _quote_dict(cls, params: dict[str,str]) -> str:
        lines = []
        for question, sql in params.items():
            question = cls._quote_text(question)
            sql = textwrap.dedent(sql)
            sql = cls._quote_text(sql)
            lines.append(f"\n        {question} = {sql}")
        return cls._parens(lines)
    
    @classmethod
    def _format_context(cls, params: dict["KineticaContextBuilder"]) -> str:
        lines = []
        for param, val in params.items():
            lines.append(f"    {param} = {val}")
        context = ',\n'.join(lines)
        return f"(\n{context}\n)"

    @classmethod
    def context_str(cls, name: str, ctx_list: list["KineticaContextBuilder"]) -> str:
        str_list = [str(ctx) for ctx in ctx_list]
        sqlcontext = ",\n".join(str_list)
        name = cls._quote_sql_obj(name) 
        return f"CREATE OR REPLACE CONTEXT {name} {sqlcontext}"


class KineticaTableDefinition(KineticaContextBuilder):
    def __init__(self, table: str, comment: str, rules = [], annotations = {}) -> None:
        self.table = table
        self.comment = comment
        self.rules = rules
        self.annotations = annotations

    def __str__(self):
        ctx_dict = {}
        ctx_dict['TABLE'] = self._quote_sql_obj(self.table)

        if self.comment != '':
            ctx_dict['COMMENT'] = self._quote_text(self.comment)
        
        if len(self.rules) > 0:
            ctx_dict['RULES'] = self._quote_list(self.rules)

        if len(self.annotations) > 0:
            ctx_dict['COMMENTS'] = self._quote_dict(self.annotations)
            
        #ctx_dict = {
        #    'TABLE': self._quote_sql_obj(self.table),
        #    'COMMENT': self._quote_text(self.comment),
        #    'RULES': self._quote_list(self.rules),
        #    'COMMENTS': self._quote_dict(self.annotations)
        #}
        return self._format_context(ctx_dict)
    

class KineticaSamplesDefinition(KineticaContextBuilder):
    def __init__(self, samples = {}) -> None:
        self.samples = samples

    def __str__(self) -> str:
        ctx_dict = {
            'SAMPLES': self._quote_dict(self.samples)
        }
        return self._format_context(ctx_dict)