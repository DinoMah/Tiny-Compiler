require 'tree'
require './src/semantic/NodoS.rb'

class AnalizadorSemantico
    public
        def getRaiz()
            return @raiz
        end

        def getSymTab()
            return @symTab
        end

        def showSymTab
            @symTab.each do |key, entry|
                puts 'Nombre: ' + @symTab[key].nombre + ', valor: ' + @symTab[key].valor.to_s + ', tipo: ' + @symTab[key].tipo
            end
        end
    private
        attr_accessor :raiz
        attr_accessor :symTab
        attr_accessor :rutaArchivo
        attr_accessor :NUM_VARIABLE
        attr_accessor :whilehijos

        def initialize( raiz, rutaArchivo )
            @raiz = raiz    
            @rutaArchivo = rutaArchivo
            @archivoErrores = File.open( 'Datos/errores_semanticos.txt', 'w' )
            @symTab = Hash.new 'NO_DISPONIBLE'
            @NUM_VARIABLE = 0
            @whilehijos = false
            crearTablaSimbolos()
            recorrerArbol( @raiz )
            showSymTab
            @archivoErrores.close
        end

        def crearTablaSimbolos()
            @raiz.postordered_each{ |nodoActual|
                if( nodoActual.parent.content.lexema == "integer" || nodoActual.parent.content.lexema == "float" || nodoActual.parent.content.lexema == "bool" || 
                    nodoActual.content.lexema == "integer" || nodoActual.content.lexema == "float" || nodoActual.content.lexema == "bool" )
                    # Va al siguiente si es el padre de las variable (integer, float o bool)
                    if( nodoActual.content.lexema == "integer" || nodoActual.content.lexema == "float" || nodoActual.content.lexema == "bool")
                        next
                    end

                    if( @symTab[nodoActual.content.lexema] == "NO_DISPONIBLE")
                        coincidencias = buscarLineas(nodoActual.content.lexema)
                        @symTab[nodoActual.content.lexema] = NodoS.new(nodoActual.content.lexema, nodoActual.parent.content.lexema, 0, @NUM_VARIABLE, coincidencias ) 
                        if nodoActual.parent.content.lexema == "integer"
                            @symTab[nodoActual.content.lexema] = NodoS.new(nodoActual.content.lexema, nodoActual.parent.content.lexema, 0, @NUM_VARIABLE, coincidencias )
                            nodoActual.content.lexema += " [tipo: " + nodoActual.parent.content.lexema + ", valor: 0]"
                        elsif nodoActual.parent.content.lexema == "float"
                            @symTab[nodoActual.content.lexema] = NodoS.new(nodoActual.content.lexema, nodoActual.parent.content.lexema, 0.0, @NUM_VARIABLE, coincidencias )
                            nodoActual.content.lexema += " [tipo: " + nodoActual.parent.content.lexema + ", valor: 0.0]"
                        else
                            @symTab[nodoActual.content.lexema] = NodoS.new(nodoActual.content.lexema, nodoActual.parent.content.lexema, nil, @NUM_VARIABLE, coincidencias )
                            nodoActual.content.lexema += " [tipo: " + nodoActual.parent.content.lexema + ", valor: nil]"
                        end
                        @NUM_VARIABLE += 1
                    else
                        lineaDeError = buscarLinea( nodoActual.parent)
                        @archivoErrores.puts( "ERROR EN LA LÍNEA #{lineaDeError}, la variable " + nodoActual.content.lexema + " ya ha sido declarada"  )
                        nodoActual.content.lexema += " [type: ERROR, valor: ERROR]"
                    end
                else
                    break
                end
            }    
        end

        def buscarLineas( lexema )
            coincidencias = ""
            archivoActual = File.open(@rutaArchivo, "r")
            numLinea = 0
            while( linea = archivoActual.gets )
                numLinea += 1
                if( linea.match?(/\b#{lexema}\b/) ) 
                    vec = linea.scan(/\b#{lexema}\b/)
                    for i in 0..vec.length-1
                        coincidencias += numLinea.to_s + ","
                    end
                end
            end
            archivoActual.close
            coincidencias[coincidencias.length-1] = ""
            return coincidencias
        end

        def buscarLinea( nodo )
            numLinea = 0
            archivoActual = File.open( @rutaArchivo, "r" )
            concuerda = false
            while( linea = archivoActual.gets )
                numLinea += 1
                nodo.each do |nodoActual|
                    posEspacio = nodoActual.content.lexema.index(' ')
                    if( posEspacio == nil )
                        posEspacio = nodoActual.content.lexema.length
                    end
                    #puts nodoActual.content.lexema[0..posEspacio-1]
                    if linea.match?(/\b#{nodoActual.content.lexema[0..posEspacio-1]}\b/)
                        concuerda = true
                    else
                        concuerda = false
                        break
                    end
                end
                if concuerda
                    break
                end
            end
            return numLinea
        end

        def recorrerArbol( raiz )
            raiz.children do |nodoActual|
                if( nodoActual.parent.content.lexema == "integer" || nodoActual.parent.content.lexema == "float" || 
                    nodoActual.parent.content.lexema == "bool" || nodoActual.content.lexema == "integer" || 
                    nodoActual.content.lexema == "float" || nodoActual.content.lexema == "bool" )
                    next
                else
                    case nodoActual.content.lexema
                    when ":="
                        recorridoPostOrden( nodoActual )
                        begin
                            llave = nil
                            @symTab.each do |key, entry|
                                if nodoActual.first_child.content.lexema.match?(/\b#{key}\b/)
                                    llave = key
                                    break
                                end
                            end
                            if(@symTab[llave].tipo == "integer" && nodoActual.last_child.content.tipo == "integer")
                                @symTab[llave].valor = nodoActual.last_child.content.valor.to_i
                                posEspacio = nodoActual.first_child.content.lexema.index(' ')
                                if posEspacio == nil
                                    posEspacio = nodoActual.first_child.content.lexema.length
                                end
                                nodoActual.first_child.content.lexema = nodoActual.first_child.content.lexema[0..posEspacio-1]
                                if @symTab[llave] != "NO_DISPONIBLE"
                                    nodoActual.first_child.content.lexema += " [tipo: " + @symTab[llave].tipo + ", valor: " + @symTab[llave].valor.to_s + "]"
                                end
                            elsif( @symTab[llave].tipo == "float" && nodoActual.last_child.content.tipo == "float")
                                @symTab[llave].valor = nodoActual.last_child.content.valor.to_f
                                posEspacio = nodoActual.first_child.content.lexema.index(' ')
                                if posEspacio == nil
                                    posEspacio = nodoActual.first_child.content.lexema.length
                                end
                                nodoActual.first_child.content.lexema = nodoActual.first_child.content.lexema[0..posEspacio-1]
                                if @symTab[llave] != "NO_DISPONIBLE"
                                    nodoActual.first_child.content.lexema += " [tipo: " + @symTab[llave].tipo + ", valor: " + @symTab[llave].valor.to_s + "]"
                                end
                            elsif( @symTab[llave].tipo == "bool" && nodoActual.last_child.content.tipo == "bool" )
                                @symTab[llave].valor = nodoActual.last_child.content.valor
                                posEspacio = nodoActual.first_child.content.lexema.index(' ')
                                if posEspacio == nil
                                    posEspacio = nodoActual.first_child.content.lexema.length
                                end
                                nodoActual.first_child.content.lexema = nodoActual.first_child.content.lexema[0..posEspacio-1]
                                if @symTab[llave] != "NO_DISPONIBLE"
                                    nodoActual.first_child.content.lexema += " [tipo: " + @symTab[llave].tipo + ", valor: " + @symTab[llave].valor.to_s + "]"
                                end
                            else
                                posEspacio = nodoActual.first_child.content.lexema.index(' ')
                                if posEspacio == nil
                                    posEspacio = nodoActual.first_child.content.lexema.length
                                end
                                @archivoErrores.puts("ERROR, no se puede asignar el valor a la variable #{nodoActual.first_child.content.lexema[0..posEspacio-1]}")
                                @symTab[llave].valor = nil
                                posEspacio = nodoActual.first_child.content.lexema.index(' ')
                                if posEspacio == nil
                                    posEspacio = nodoActual.first_child.content.lexema.length
                                end
                                nodoActual.first_child.content.lexema = nodoActual.first_child.content.lexema[0..posEspacio-1]
                                nodoActual.first_child.content.lexema += " [tipo: " + @symTab[llave].tipo + ", valor: ERROR]"
                            end
                        rescue
                            posEspacio = nodoActual.first_child.content.lexema.index(' ')
                            if posEspacio == nil
                                posEspacio = nodoActual.first_child.content.lexema.length
                            end
                            @archivoErrores.puts("ERROR, la variable #{nodoActual.first_child.content.lexema[0..posEspacio-1]} no está declarada")
                        end
                    when "if"
                        nodoActual.children do |hijo|
                            hijo.children do |nieto|
                                puts nieto.content.lexema
                                case nieto.content.lexema
                                when "<", ">", "<=", ">=", "==", "!=", "+", "-", "*", "/", "%"
                                    recorridoPostOrden( nieto )
                                when ":="
                                    recorrerArbol( hijo )
                                when "if"
                                    recorrerArbol( nieto )
                                when "do"
                                    recorrerArbol( nieto )
                                when "while"
                                    recorrerArbol( nieto )
                                else
                                    if( nieto.content.token == "id" || nieto.content.token == "num entero" || nieto.content.token == "num real" )
                                        recorridoPostOrden( nieto )
                                    end
                                end
                            end
                        end
                    when "while"
                        nodoActual.children do |hijo|
                            puts hijo.content.lexema
                            if( !@whilehijos )
                                case hijo.first_child.content.lexema
                                when "<", ">", "<=", ">=", "==", "!=", "+", "-", "*", "/", "%"
                                    recorridoPostOrden( hijo.first_child )
                                else
                                    if hijo.first_child.content.token == "id" || hijo.first_child.content.token == "num entero" || hijo.first_child.content.token == "num real"
                                        recorridoPostOrden( hijo.first_child)
                                    end
                                end
                                @whilehijos = true
                            else                       
                                case hijo.content.lexema
                                when ":="
                                    recorrerArbol( nodoActual )
                                when "if"
                                    recorrerArbol( nodoActual )
                                when "do"
                                    recorrerArbol( nodoActual )
                                when "while"
                                    recorrerArbol( nodoActual )
                                when "read"
                                    recorrerArbol( nodoActual )
                                when "write"
                                    recorridoPostOrden( hijo )
                                end
                            end
                        end
                        @whilehijos = false
                    when "do" 
                        nodoActual.children do |hijo|
                            puts hijo.content.lexema
                            if( hijo.content.lexema != "until")
                                case hijo.content.lexema
                                when ":="
                                    recorrerArbol( nodoActual )
                                when "if"
                                    recorrerArbol( nodoActual )
                                when "do"
                                    recorrerArbol( nodoActual )
                                when "while"
                                    recorrerArbol( nodoActual )
                                when "read"
                                    recorrerArbol( nodoActual )
                                when "write"
                                    recorridoPostOrden( hijo )
                                end
                            else
                                nieto = hijo.first_child.first_child
                                case nieto.content.lexema
                                when "<", ">", "<=", ">=", "==", "!=", "+", "-", "*", "/", "%"
                                    recorridoPostOrden( nieto )
                                else
                                    if nieto.content.token == "id" || nieto.content.token == "num entero" || nieto.content.token == "num real"
                                        recorridoPostOrden( nieto )
                                    end
                                end
                            end    
                        end
                    when "read"
                        recorridoPostOrden( nodoActual ) 
                    when "write"
                        recorridoPostOrden( nodoActual.last_child)                 
                    end
                end
            end
        end

        def recorridoPostOrden( nodoActual )
            nodoActual.postordered_each do |nodo|
                case nodo.content.lexema
                when "+"
                    begin
                        nodo.content.valor = nodo.first_child.content.valor + nodo.last_child.content.valor
                        if nodo.first_child.content.tipo == nodo.last_child.content.tipo
                            nodo.content.tipo = nodo.last_child.content.tipo
                            nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else
                            if nodo.first_child.content.tipo == "integer"
                                nodo.content.tipo = nodo.last_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            else
                                nodo.content.tipo = nodo.first_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.first_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            end
                        end
                    rescue
                        posEspacio1 = nodo.first_child.content.lexema.index(' ')
                        if posEspacio1 == nil
                            posEspacio1 = nodo.first_child.content.lexema.length
                        end
                        posEspacio2 = nodo.last_child.content.lexema.index(' ')
                        if posEspacio2 == nil
                            posEspacio2 = nodo.last_child.content.lexema.length
                        end
                        @archivoErrores.puts("ERROR EN LA OPERACIÓN #{nodo.first_child.content.lexema[0..posEspacio1]} + #{nodo.last_child.content.lexema[0..posEspacio2]}" )
                    end
                when "-"
                    begin
                        nodo.content.valor = nodo.first_child.content.valor - nodo.last_child.content.valor
                        if nodo.first_child.content.tipo == nodo.last_child.content.tipo
                            nodo.content.tipo = nodo.last_child.content.tipo
                            nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else
                            if nodo.first_child.content.tipo == "integer"
                                nodo.content.tipo = nodo.last_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            else
                                nodo.content.tipo = nodo.first_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.first_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            end
                        end
                    rescue
                        posEspacio1 = nodo.first_child.content.lexema.index(' ')
                        if posEspacio1 == nil
                            posEspacio1 = nodo.first_child.content.lexema.length
                        end
                        posEspacio2 = nodo.last_child.content.lexema.index(' ')
                        if posEspacio2 == nil
                            posEspacio2 = nodo.last_child.content.lexema.length
                        end
                        @archivoErrores.puts("ERROR EN LA OPERACIÓN #{nodo.first_child.content.lexema[0..posEspacio1]} - #{nodo.last_child.content.lexema[0..posEspacio2]}" )
                    end
                when "*"
                    begin
                        nodo.content.valor = nodo.first_child.content.valor * nodo.last_child.content.valor
                        if nodo.first_child.content.tipo == nodo.last_child.content.tipo
                            nodo.content.tipo = nodo.last_child.content.tipo
                            nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else
                            if nodo.first_child.content.tipo == "integer"
                                nodo.content.tipo = nodo.last_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            else
                                nodo.content.tipo = nodo.first_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.first_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            end
                        end
                    rescue
                        posEspacio1 = nodo.first_child.content.lexema.index(' ')
                        if posEspacio1 == nil
                            posEspacio1 = nodo.first_child.content.lexema.length
                        end
                        posEspacio2 = nodo.last_child.content.lexema.index(' ')
                        if posEspacio2 == nil
                            posEspacio2 = nodo.last_child.content.lexema.length
                        end
                        @archivoErrores.puts("ERROR EN LA OPERACIÓN #{nodo.first_child.content.lexema[0..posEspacio1]} * #{nodo.last_child.content.lexema[0..posEspacio2]}" )
                    end
                when "/"
                    begin
                        nodo.content.valor = nodo.first_child.content.valor / nodo.last_child.content.valor
                        if nodo.first_child.content.tipo == nodo.last_child.content.tipo
                            nodo.content.tipo = nodo.last_child.content.tipo
                            nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else
                            if nodo.first_child.content.tipo == "integer"
                                nodo.content.tipo = nodo.last_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            else
                                nodo.content.tipo = nodo.first_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.first_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            end
                        end
                    rescue
                        posEspacio1 = nodo.first_child.content.lexema.index(' ')
                        if posEspacio1 == nil
                            posEspacio1 = nodo.first_child.content.lexema.length
                        end
                        posEspacio2 = nodo.last_child.content.lexema.index(' ')
                        if posEspacio2 == nil
                            posEspacio2 = nodo.last_child.content.lexema.length
                        end
                        @archivoErrores.puts("ERROR EN LA OPERACIÓN #{nodo.first_child.content.lexema[0..posEspacio1]} / #{nodo.last_child.content.lexema[0..posEspacio2]}" )
                    end
                when "%"
                    begin
                        nodo.content.valor = nodo.first_child.content.valor % nodo.last_child.content.valor
                        if nodo.first_child.content.tipo == nodo.last_child.content.tipo
                            nodo.content.tipo = nodo.last_child.content.tipo
                            nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else
                            if nodo.first_child.content.tipo == "integer"
                                nodo.content.tipo = nodo.last_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.last_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            else
                                nodo.content.tipo = nodo.first_child.content.tipo
                                nodo.content.lexema += " [tipo: "  + nodo.first_child.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                            end
                        end
                    rescue
                        posEspacio1 = nodo.first_child.content.lexema.index(' ')
                        if posEspacio1 == nil
                            posEspacio1 = nodo.first_child.content.lexema.length
                        end
                        posEspacio2 = nodo.last_child.content.lexema.index(' ')
                        if posEspacio2 == nil
                            posEspacio2 = nodo.last_child.content.lexema.length
                        end
                        @archivoErrores.puts("ERROR EN LA OPERACIÓN #{nodo.first_child.content.lexema[0..posEspacio1]} % #{nodo.last_child.content.lexema[0..posEspacio2]}" )
                    end
                when "<"
                    if( nodo.first_child.content.valor < nodo.last_child.content.valor )
                        nodo.content.valor = true
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    else
                        nodo.content.valor = false
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    end
                when ">"
                    if( nodo.first_child.content.valor > nodo.last_child.content.valor )
                        nodo.content.valor = true
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    else
                        nodo.content.valor = false
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    end
                when "<="
                    if( nodo.first_child.content.valor <= nodo.last_child.content.valor )
                        nodo.content.valor = true
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    else
                        nodo.content.valor = false
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    end
                when ">="
                    if( nodo.first_child.content.valor >= nodo.last_child.content.valor )
                        nodo.content.valor = true
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    else
                        nodo.content.valor = false
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    end
                when "=="
                    if( nodo.first_child.content.valor == nodo.last_child.content.valor )
                        nodo.content.valor = true
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    else
                        nodo.content.valor = false
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    end
                when "!="
                    if( nodo.first_child.content.valor != nodo.last_child.content.valor )
                        nodo.content.valor = true
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    else
                        nodo.content.valor = false
                        nodo.content.tipo = "bool"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    end
                else
                    case nodo.content.token
                    when "num entero"
                        posEspacio = nodo.content.lexema.index(' ')
                        if posEspacio == nil
                            posEspacio = nodo.content.lexema.length
                        end
                        nodo.content.lexema = nodo.content.lexema[0..posEspacio-1]
                        nodo.content.valor = nodo.content.lexema.to_i
                        nodo.content.tipo = "integer"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    when "num real"
                        posEspacio = nodo.content.lexema.index(' ')
                        if posEspacio == nil
                            posEspacio = nodo.content.lexema.length
                        end
                        nodo.content.lexema = nodo.content.lexema[0..posEspacio-1]
                        nodo.content.valor = nodo.content.lexema.to_f
                        nodo.content.tipo = "float"
                        nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                    when "id"
                        posEspacio = nodo.content.lexema.index(' ')
                        if posEspacio == nil
                            posEspacio = nodo.content.lexema.length
                        end
                        nodo.content.lexema = nodo.content.lexema[0..posEspacio-1]
                        if( @symTab[nodo.content.lexema] != "NO_DISPONIBLE" )
                            nodo.content.valor = @symTab[nodo.content.lexema].valor
                            nodo.content.tipo = @symTab[nodo.content.lexema].tipo
                            nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else
                            @archivoErrores.puts( "ERROR EN LA VARIABLE " + nodo.content.lexema + ", la variable no ha sido declarada")
                            nodo.content.lexema += " [tipo: ERROR, valor: ERROR]"
                        end
                    end
                end
            end
        end
end