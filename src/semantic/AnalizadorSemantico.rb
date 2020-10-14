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
                # Verifica si el padre de la variable es entero, flotante o booleano O si el nodo es es un flotante, entero o booleano
                if( nodoActual.parent.content.lexema == "integer" || nodoActual.parent.content.lexema == "float" || nodoActual.parent.content.lexema == "bool" || 
                    nodoActual.content.lexema == "integer" || nodoActual.content.lexema == "float" || nodoActual.content.lexema == "bool" )
                    # Va al siguiente si es el padre de las variable (integer, float o bool)
                    if( nodoActual.content.lexema == "integer" || nodoActual.content.lexema == "float" || nodoActual.content.lexema == "bool")
                        next
                    end
                    
                    # Verifica si la variable no ha sido declarada anteriormente
                    if( @symTab[nodoActual.content.lexema] == "NO_DISPONIBLE")
                        coincidencias = buscarLineas(nodoActual.content.lexema) # Busca todas las coincidencias de la variable en el archivo de código
                        # Crea el espacio para la variable declarada
                        # La siguiente línea es innecesaria :v (no la borro por cuestiones de que ya no le quiero mover xD)
                        @symTab[nodoActual.content.lexema] = NodoS.new(nodoActual.content.lexema, nodoActual.parent.content.lexema, 0, @NUM_VARIABLE, coincidencias ) 
                        # Crea el espacio según su tipo de dato además de que hace una anotacion en el árbol sintactico/semantico
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
                        # Marca error si la variable ha sido declara anteriormente
                        lineaDeError = buscarLinea( nodoActual.parent)
                        @archivoErrores.puts( "ERROR EN LA LÍNEA #{lineaDeError}, la variable " + nodoActual.content.lexema + " ya ha sido declarada"  )
                        nodoActual.content.lexema += " [type: ERROR, valor: ERROR]"
                    end
                else
                    # Si el nodo no es una declaracion de variable termina.
                    break
                end
            }    
        end

        # Las siguientes 2 funciones buscan las coincidencias de la variable en todo el código

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

        # Funcion recursiva que recorre por cada hijo del nodo enviado como parámetro
        # Si ves cosas como esa -> posEspacio = nodoActual.first_child.content.lexema.index(' ') ignoralas, es por cosa de mi interfaz :v, las anotaciones se identifica por que se separan con un espacio
        def recorrerArbol( raiz )
            raiz.children do |nodoActual|
                if( nodoActual.parent.content.lexema == "integer" || nodoActual.parent.content.lexema == "float" || 
                    nodoActual.parent.content.lexema == "bool" || nodoActual.content.lexema == "integer" || 
                    nodoActual.content.lexema == "float" || nodoActual.content.lexema == "bool" )
                    # Si es una declaracion de variable no lo haga, por que ya analizamos anteriormente esta parte para crear la tabla de símbolos
                    next
                else
                    case nodoActual.content.lexema # Verifica que tipo de nodo es (:=, if, do, while, read, write)
                    when ":="
                        recorridoPostOrden( nodoActual )
                        begin
                            llave = nil
                            @symTab.each do |key, entry| # Busca la variable en la tabla de simbolos
                                if nodoActual.first_child.content.lexema.match?(/\b#{key}\b/)
                                    llave = key
                                    break
                                end
                            end
                            # Si el tipo de la variable y el tipo del valor a asignar coinciden se asigna, caso contrario se marca error
                            if(@symTab[llave].tipo == "integer" && nodoActual.last_child.content.tipo == "integer") # Verifica el ultimo hijo por que tiene dos hijos, la variable a la que va a asignar y lo que le va a asignar
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
                            # Si la variable no esta declarada llega este punto marcando el problema
                            posEspacio = nodoActual.first_child.content.lexema.index(' ')
                            if posEspacio == nil
                                posEspacio = nodoActual.first_child.content.lexema.length
                            end
                            @archivoErrores.puts("ERROR, la variable #{nodoActual.first_child.content.lexema[0..posEspacio-1]} no está declarada")
                        end
                    when "if"
                        # if tiene 3 hijos o 2 siendo exp, true y false, false siendo opcional (else)
                        nodoActual.children do |hijo| # Se recorre cada hijo de if
                            hijo.children do |nieto| # Se recorre cada hijo de exp o true o false
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
                    when "while" # While tiene n hijos, el primero siendo la expresion a evaluar (2 > 3 por ejemplo) y los demas siendo cada una de las sentencias dentro de el.
                        nodoActual.children do |hijo|
                            puts hijo.content.lexema
                            if( !@whilehijos ) # Evalua la expresion
                                case hijo.first_child.content.lexema
                                when "<", ">", "<=", ">=", "==", "!=", "+", "-", "*", "/", "%"
                                    recorridoPostOrden( hijo.first_child )
                                else
                                    if hijo.first_child.content.token == "id" || hijo.first_child.content.token == "num entero" || hijo.first_child.content.token == "num real"
                                        recorridoPostOrden( hijo.first_child)
                                    end
                                end
                                @whilehijos = true
                            else # Checa cada sentencia dentro del while
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
                    when "do" # do tiene n hijos, siendo el hijo n la expresion, similar al while nada más a la inversa xD
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
                        recorridoPostOrden( nodoActual ) # Read solo puede tener un hijo
                    when "write" # Write tiene dos hijos, la cadena y la expresion, esta última se analiza en recorridoPostOrden
                        recorridoPostOrden( nodoActual.last_child)                 
                    end
                end
            end
        end

        # Si cae en cualquiera de los operandos siguientes "<", ">", "<=", ">=", "==", "!=", "+", "-", "*", "/", "%" se analiza aqui
        def recorridoPostOrden( nodoActual ) # Esta funcion solo se usa para expresiones por ejemplo 3 + 4, 7- 5 y asi
            nodoActual.postordered_each do |nodo|
                case nodo.content.lexema # Todas las operaciones aqui son binarias, por lo tanto tienen solo 2 hijos maximo (first_child y last_child) o pueden ser hojas (sin hijos)
                when "+"
                    begin
                        nodo.content.valor = nodo.first_child.content.valor + nodo.last_child.content.valor # Se realiza la operacion
                        if nodo.first_child.content.tipo == nodo.last_child.content.tipo # Se verifica que los tipos sean correctos
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
                        # Esto se ejecuta si la operacion no se puede concretar (en la siguientes funciones son similares)
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
                        # Puede que caiga aqui si el divisor es 0
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
                    # Realiza la comparacion ademas de anotar en el arbol sintactico los resultados
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
                    # Cae aqui si es un numero o un id
                    case nodo.content.token
                    when "num entero"
                        posEspacio = nodo.content.lexema.index(' ')
                        if posEspacio == nil
                            posEspacio = nodo.content.lexema.length
                        end
                        nodo.content.lexema = nodo.content.lexema[0..posEspacio-1]
                        nodo.content.valor = nodo.content.lexema.to_i # Convierte el string en int
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
                        if( @symTab[nodo.content.lexema] != "NO_DISPONIBLE" ) # Verifica si la variable esta declarada
                            nodo.content.valor = @symTab[nodo.content.lexema].valor
                            nodo.content.tipo = @symTab[nodo.content.lexema].tipo
                            nodo.content.lexema += " [tipo: " + nodo.content.tipo + ", valor: " + nodo.content.valor.to_s + "]"
                        else # Marca error si la variable no ha sido declarada
                            @archivoErrores.puts( "ERROR EN LA VARIABLE " + nodo.content.lexema + ", la variable no ha sido declarada")
                            nodo.content.lexema += " [tipo: ERROR, valor: ERROR]"
                        end
                    end
                end
            end
        end
end