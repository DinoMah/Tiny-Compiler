class NodoS
    attr_accessor :nombre
    attr_accessor :tipo
    attr_accessor :valor
    attr_accessor :direccionMem
    attr_accessor :numsLinea

    def initialize
        @nombre = ""
        @tipo = ""
        @valor = 0
        @direccionMem = ""
        @numsLinea = ""
    end

    def initialize(nombre, tipo, valor, direccionMem, numsLinea)
        @nombre = nombre
        @tipo = tipo
        @valor = valor
        @direccionMem = direccionMem
        @numsLinea = []
        @numsLinea = numsLinea
    end
end