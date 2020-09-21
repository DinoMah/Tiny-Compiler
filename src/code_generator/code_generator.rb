class CodeGenerator
    attr_accessor :syntaxTree
    attr_writer :assembliesFile
    attr_accessor :numOfLabels
    
    def initialize(syntaxTree)
        self.syntaxTree = syntaxTree
        self.assembliesFile = File.open 'Datos/assemblies.txt', 'w'
        @assembliesFile.close
        self.numOfLabels = 0
    end

    public def genCode(treeNode) # Generates code for the operation, puede recorrer el nodo en inorden, postorden, dependiendo del tipo de nodo
        if treeNode != nil
            case treeNode.content.token
            when 'palabra reservada'
                self.onReservedWord treeNode
            when 'id'
                self.onIdentificator treeNode
            when 'num entero', 'num real'
                self.onNumber treeNode
            when 'cadena'
                self.onString treeNode
            when 'suma', 'resta', 'multiplicacion', 'div', 'residuo', 'asignacion'
                self.onOperator treeNode
            when 'mayor', 'menor', 'may_igual', 'men_igual', 'com_igual', 'com_dif'
                self.onCompareOperator treeNode
            else
                self.onError
            end
        end
    end

    private
    def onReservedWord(treeNode) # Does the code for the reserved word
        case treeNode.content.lexema
        when 'if'
            self.onIf treeNode
        when 'do'
            self.onDo treeNode
        when 'while'
            self.onWhile treeNode
        when 'write'
            self.onWrite treeNode
        when 'read'
            self.onRead treeNode
        when 'integer', 'float', 'bool'
            # No hara nada :D
        else
            self.onError
        end
    end

    def onIf(treeNode)
        self.constructCondition treeNode
        lab1 = self.getLabelNumber
        self.onSave 'fjp L' + lab1, nil
        self.genCode treeNode.children[1].first_child
        
        if treeNode.children[2] != nil
            lab2 = self.getLabelNumber
            self.onSave 'ujp L' + lab2, nil
        end
        
        self.onSave 'lab L' + lab1, nil

        if treeNode.children[2] != nil
            self.genCode treeNode.children[2].first_child
            self.onSave 'lab L' + lab2, nil
        end
    end

    def onWhile(treeNode)
        lab1 = self.getLabelNumber
        self.onSave 'lab L' + lab1, nil
        self.constructCondition treeNode
        lab2 = self.getLabelNumber
        self.onSave 'fjp L' + lab2, nil
        
        treeNode.first_child.siblings do |sibling|
            self.genCode sibling
        end
        self.onSave 'ujp L' + lab1, nil
        self.onSave 'lab L' + lab2, nil
    end

    def onDo(treeNode)
        lab1 = self.getLabelNumber
        self.onSave 'lab L' + lab1, nil
        treeNode.last_child.siblings do |sibling|
            self.genCode sibling
        end
        lab2 = self.getLabelNumber
        self.onUntil treeNode
        self.onSave 'fjp L' + lab2, nil
        self.onSave 'ujp L' + lab1, nil
        self.onSave 'lab L' + lab2, nil
    end

    def onUntil(treeNode)
        # El nodo until (que es el último en la expresión Do) tiene la siguiente estructura
        # until
        #   exp
        #       nodoQueIniciaLaExpresion
        self.genCode treeNode.last_child.first_child.first_child
    end

    def constructCondition(treeNode) # Genera el código para la expresión de un if, do o while
        self.genCode treeNode.first_child.first_child
    end

    def onWrite(treeNode)
        self.onString treeNode.first_child
        if treeNode.children.length > 1
            self.genCode treeNode.last_child
        end
        self.onSave 'wri', nil
    end

    def onRead(treeNode)
        self.onSave 'lda ', treeNode.first_child
        self.onSave 'rdi', nil
    end

    def onIdentificator(treeNode)
        self.onSave 'lod', treeNode
    end

    def onNumber(treeNode)
        self.onSave 'ldc', treeNode
    end

    def onOperator(treeNode)
        case treeNode.content.lexema
        when '+'
            self.onOperation 'adi', treeNode
        when '-'
            self.onOperation 'sub', treeNode
        when '*'
            self.onOperation 'mul', treeNode
        when '/'
            self.onOperation 'div', treeNode
        when '%'
            self.onOperation 'res', treeNode
        when ':='
            self.onSave 'lda', treeNode.first_child
            self.genCode treeNode.last_child
            self.onSave 'stn', nil
        else
            self.onError
        end
    end

    def onOperation(operation, treeNode)
        self.genCode treeNode.first_child
        self.genCode treeNode.last_child
        self.onSave operation, nil
    end

    def onString(treeNode)
        codeString = 'lds ' + treeNode.content.lexema
        self.writeToFile codeString
    end

    def onCompareOperator(treeNode)
        case treeNode.content.lexema
        when '>'
            self.onOperation 'gtn', treeNode
        when '<'
            self.onOperation 'ltn', treeNode
        when '>='
            self.onOperation 'gte', treeNode
        when '<='
            self.onOperation 'lte', treeNode
        when '=='
            self.onOperation 'equ', treeNode
        when '!='
            self.onOperation 'dif', treeNode
        else
            self.onError
        end
    end

    def onError
        self.onSave 'Error', nil
    end

    def getLabelNumber
        self.numOfLabels += 1
        return @numOfLabels.to_s
    end

    def onSave(command, treeNode) # Hace la concatenación del comando y el valor, puede existir un comando sin valor.
        if treeNode != nil
            codeString = command + ' ' + treeNode.content.lexema
        else
            codeString = command
        end
        self.writeToFile codeString
    end

    def writeToFile(codeString)
        # File where is the generated code
        @assembliesFile = File.open 'Datos/assemblies.txt', 'a'
        @assembliesFile.puts codeString
        @assembliesFile.close
    end
end