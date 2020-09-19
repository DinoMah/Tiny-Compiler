class Nodo
    #Elementos para el analizador sintáctico.
    attr_accessor :lexema # Token
    attr_accessor :token # Tipo del token
    attr_accessor :lineNumber # Número de línea donde se encuentra
    attr_accessor :valor # ?
    attr_accessor :tipo
    
    # pos 1 -> token, pos 2 -> token type, pos 3 -> posible line number, may be nil
    def initialize(*args)
        @lexema = args[0]
        @token = args[1]
        @lineNumber = args[2]
        @valor = 0
        @tipo = ""
    end
end