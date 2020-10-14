class NodoS
    attr_accessor :nombre
    attr_accessor :tipo
    attr_accessor :valor
    attr_accessor :direccionMem
    attr_accessor :numsLinea

    def initialize(*args)
        @nombre = args[0]
        @tipo = args[1]
        @valor = args[2]
        @direccionMem = args[3]
        @numsLinea = args[4]
    end
end