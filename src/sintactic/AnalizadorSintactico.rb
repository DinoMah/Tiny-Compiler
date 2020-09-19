require 'tree'
require "./src/sintactic/Nodo.rb"

class AnalizadorSintactico
	# TODO: Expresión creo que regresa nodos nulos, cambiar a que no regrese nodos nulos.

	private
		attr_accessor :heAcabado, :enDeclaraciones
		attr_accessor :archivoTokens, :archivoErrores, :codeFile # Archivo de los tokens y los errores resultantes
		attr_accessor :tokenList # Lista de tokens completa
		attr_accessor :raiz, :nodoActual, :numNodo, :numExp # Variables que tal vez no se queden (excepto :raiz)
		attr_accessor :hayError, :mensaje_error
		attr_accessor :sentenciaActual

		def initialize(filePath)
			@archivoTokens = File.open( "tokenLexico.txt", 'r' )
			@archivoErrores = File.open( "Datos/errores_sintacticos.txt", 'w' )
			@codeFile = File.open(filePath, 'r')
			@raiz = nil
			@tokenList = []
			@numNodo = 0
			@hayError = false
			@mensaje_error = ''
			@sentenciaActual = ''

			fillTokenList()
			@numExp = @tokenList.length
			# We init the parsing process
			programa()

			@nodoActual = nil
			@heAcabado = false
			@enDeclaraciones = false
			
			@archivoTokens.close
			@archivoErrores.close
			@codeFile.close
		end

		def fillTokenList() 
			numLinea = 1
			# Sacamos la primer línea del archivo y guardamos el token y el tipo del token.
			line = @archivoTokens.gets.split("-> ")
			tokenType = line[0] # Gets token type
			token = line[1].strip! # Gets token
			# Por cada línea vamos a hacer lo mismo
			# Verificamos si se encuentra en la línea actual, sí se encuentra lo agregamos a la lista
			# Si no se encuentra pasamos a la siguiente línea y volvemos a hacer la verificación.
			# Se van quitando las coincidencias para evitar repeticiones
			while(codeLine = @codeFile.gets)
				while(true)
					if(codeLine.include? token)
						codeLine.sub!(token, "".clear)
						@tokenList.push(Nodo.new(token, tokenType, numLinea))
					else
						numLinea += 1
						break
					end
					if (line = @archivoTokens.gets)
						line = line.split("-> ")
						tokenType = line[0] # Gets token type
						token = line[1].strip! # Gets token
					else
						break
					end
				end
			end
			# showTokens()
		end

		def showTokens()
			for i in 0...@tokenList.length
				puts "Token: " + @tokenList[i].lexema + ", Type: " + @tokenList[i].token + ", # Línea: " + @tokenList[i].lineNumber.to_s()
			end
		end

		def showTree()
			@raiz.each do |node|
				puts node.content.lexema
			end
		end

		def getToken()
			if(@numNodo != @tokenList.length)
				@numNodo += 1
			else
				@heAcabado = true
			end
		end

		def match(tokenEsperado, *args)
			if(!@heAcabado)
				if(@tokenList[@numNodo].lexema == tokenEsperado)
					getToken()
				else
					if args == nil # args will contain the message sent by the caller of the function
						@archivoErrores.puts("ERROR EN " + @tokenList[@numNodo].lexema + ", se esperaba -> " + tokenEsperado + "\n")
					else
						@archivoErrores.puts args[0]
					end
					# treatment()
				end
			end
		end

		def treatment()
			if( @enDeclaraciones )
				while( (@tokenList[@numNodo].token != "punto y coma") )
					getToken()
				end
				match(";")
				if( (@tokenList[@numNodo].lexema != "integer") && (@tokenList[@numNodo].lexema != "bool") && (@tokenList[@numNodo].lexema != "float") )
					@enDeclaraciones = false
					return
				end
				listaDeclaraciones()
			else
				if (@tokenList.length - @numNodo) == 1
					return
				end
				
				puts 'Tokens desechados:'
				
				case @sentenciaActual
				when 'if', 'while'
				when 'read', 'write'
				when 'bloque'
				when 'do'
				else
				end
				while @tokenList[@numNodo].lexema != ';'  && @tokenList[@numNodo].lexema != '}'
					puts @tokenList[@numNodo].lexema
					match @tokenList[@numNodo].lexema
				end
				puts 'END'
				if @tokenList[@numNodo].lexema == ';'
					match ';'
				else
					match '}'
				end
				@hayError = false
				@mensaje_error = ''
			end
		end

		#REGLA: programa -> main { lista-declaracion lista-sentencias }
		def programa()
			if( !@heAcabado )
				@raiz = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				@nodoActual = @raiz
				match("main")
				match("{")
				@enDeclaraciones = true
				listaDeclaraciones()
				@enDeclaraciones = false
				listaSentencias(@raiz)
				match("}")
			end
		end

		#BNF: lista-declaracion -> declaracion ; lista-declaracion | vacio
		#EBNF: lista-declaracion -> { declaracion ; } vacio
		def listaDeclaraciones()
			if( (@tokenList[@numNodo].lexema == "integer") || (@tokenList[@numNodo].lexema == "bool") || (@tokenList[@numNodo].lexema == "float") )
				while( (@tokenList[@numNodo].lexema == "integer") || (@tokenList[@numNodo].lexema == "bool") || (@tokenList[@numNodo].lexema == "float") )
					@nodoActual = @raiz
					nodoNuevo = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
					@nodoActual << nodoNuevo
					@nodoActual = nodoNuevo
					match( @tokenList[@numNodo].lexema )
					declaracion()
					if( @enDeclaraciones )
						match(";")
					else
						return
					end
				end
				if( (@tokenList[@numNodo].lexema != "integer") && (@tokenList[@numNodo].lexema != "bool") && (@tokenList[@numNodo].lexema != "float") )
					@enDeclaraciones = false
					return
				end
			else
				@archivoErrores.puts "ERROR EN " + @tokenList[@numNodo].lexema + " línea # #{@tokenList[@numNodo].lineNumber}, se esperaba alguno de los siguientes: \n-> integer\n-> bool\n-> float\n"
				treatment()				
			end
		end

		#BNF: declaracion -> tipo lista-variables
		#EBNF: Así se queda
		def declaracion()
			listaVariables()
		end

		
		#BNF: lista-variables -> identificador , lista-variables | identificador 
		#EBNF: lista-variables -> { identificador , } identificador
		def listaVariables()
			while( @tokenList[@numNodo].token == "id" )
				nodoNuevo = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				@nodoActual << nodoNuevo
				match( @tokenList[@numNodo].lexema )
				if( @tokenList[@numNodo].lexema != "," )
					if( @tokenList[@numNodo].lexema != ";" )
						@archivoErrores.puts( "ERROR EN " + @tokenList[@numNodo].lexema + ", se esperaba -> ;" )
						treatment()
					end
					break
				end
				match(",")
				if( @tokenList[@numNodo].token != "id" )
					@archivoErrores.puts( "ERROR EN " + @tokenList[@numNodo].lexema + ", se esperaba -> id" )
					treatment()
				end
			end
		end

		#BNF: lista-sentencias -> sentencia lista-sentencias | sentencia | vacío
		#EBNF: lista-sentencias -> { sentencia } vacío
		def listaSentencias(padre)
			begin
				until  @tokenList[@numNodo].lexema == '}' || (@tokenList.length - @numNodo) <= 1
					hijo = sentencia()
					padre << hijo unless hijo == nil # Si es nulo no inserta nada.
					case @tokenList[@numNodo].lexema
					when 'if', 'while', 'do', 'write', 'read'
						next
					when '}'
						break
					else
						if @tokenList[@numNodo].token == 'id'
							next
						else
							match '', "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba alguna palabra reservada o algún identificador"
						end
					end
				end
			rescue
				puts 'Que ya no hay tokens coño!'
			end
		end

		#REGLA: sentencia -> selección | iteración | repetición | sent-read | sent-write | bloque | asignación
		def sentencia()
			nodoNuevo = nil
			case @tokenList[@numNodo].lexema
			when "if"
				nodoNuevo = seleccion()
			when "while"
				nodoNuevo = iteracion()
			when "do"
				nodoNuevo = repeticion()
			when "read"
				nodoNuevo = read()
			when "write"
				nodoNuevo = write()
			else
				if( @tokenList[@numNodo].token == "id" )
					nodoNuevo = asignacion()
				end
			end

			if @hayError
				match '', @mensaje_error
			end
			
			return esNulo? nodoNuevo
		end

		#REGLA: selección -> if ( expresión ) then bloque | if ( expresión ) then bloque else bloque
		# EBNF: selección -> if ( expresión ) then bloque [ else bloque ]
		def seleccion() # TODO: Se modificó hasta la línea 286
			if !@heAcabado
				nodoNuevo = Tree::TreeNode.new( @numNodo.to_s + ' if', Nodo.new(@tokenList[@numNodo].lexema, @tokenList[@numNodo].token ) )
				match 'if'

				#Se crea el apartado de la expresión
				nodoNuevo1 = Tree::TreeNode.new( @numExp.to_s + ' exp', Nodo.new('exp', '') )
				@numExp += 1
				nodoNuevo << nodoNuevo1

				temp = expresion()
				if !@hayError
					nodoNuevo1 << temp
				end

				#Se crea el apartado en caso de que la expresión sea verdadera
				if @tokenList[@numNodo].lexema == 'then'
					match 'then'
					nodoNuevo2 = Tree::TreeNode.new( @numExp.to_s + ' true', Nodo.new('true', '') )
					@numExp += 1
					nodoNuevo << nodoNuevo2
					bloque(nodoNuevo2)
					if !@hayError
						#Se crea el apartado en caso de que la expresión sea falsa
						if @tokenList[@numNodo].lexema == 'else'
							nodoNuevo3 = Tree::TreeNode.new( @numExp.to_s+ ' false', Nodo.new('false', '') )
							@numExp += 1
							nodoNuevo << nodoNuevo3
							match @tokenList[@numNodo].lexema
							bloque( nodoNuevo3 )
						end
					end
				else
					@hayError = true
					@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba palabra reservada 'then'"
				end
				return nodoNuevo
			end
		end

		#REGLA: iteración -> while ( expresión ) bloque
		def iteracion()
			if !@heAcabado
				nodoNuevo1 = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				match 'while'
				exp = Tree::TreeNode.new( @numExp.to_s + ' exp', Nodo.new('exp', @tokenList[@numNodo].token) )
				@numExp += 1
				nodoNuevo1 << exp
				nodoNuevo2 = expresion()

				if !@hayError
					exp << nodoNuevo2
				end

				bloque nodoNuevo1

				return nodoNuevo1
			end
		end

		#BNF: repetición -> do bloque until ( expresión ) ;
		def repeticion()
			if !@heAcabado
				nodoNuevo1 = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				match 'do'
				
				bloque nodoNuevo1
				nodoNuevo1.print_tree
					if @tokenList[@numNodo].lexema == 'until'
						nodoNuevo3 = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
						nodoNuevo1 << nodoNuevo3
						match 'until'

						nodoNuevo4 = Tree::TreeNode.new( @numExp.to_s + ' exp', Nodo.new('exp', '') )
						@numExp += 1
						nodoNuevo3 << nodoNuevo4
						nodoNuevo5 = expresion()
						
						if !@hayError
							nodoNuevo4 << nodoNuevo5
						end
						match ';'
					else
						@hayError = true
						@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba palabra reservada 'until'"
					end
				return nodoNuevo1
			end
		end

		#REGLA: sent-read -> read identificador ;
		def read()
			nodoNuevo1 = Tree::TreeNode.new(@numNodo.to_s + ' read', Nodo.new(@tokenList[@numNodo].lexema, @tokenList[@numNodo].token))
			match "read"
			if( @tokenList[@numNodo].token == "id" )
				nodoNuevo2 = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				nodoNuevo1 << nodoNuevo2
				match @tokenList[@numNodo].lexema
				match ";"
			else
				@hayError = true
				@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba un identificador"
			end
			return nodoNuevo1
		end

		#REGLA: sent-write -> write cadena expresión | cadena ;
		# EBNF: sent-write -> write cadena [ , expresión ] ;
		def write()
			if !@heAcabado
				nodoNuevo1 = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				match 'write'
				if @tokenList[@numNodo].token == 'cadena'
					nodoNuevo2 = Tree::TreeNode.new( @numNodo.to_s + " #{@tokenList[@numNodo].lexema}", Nodo.new(@tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
					nodoNuevo1 << nodoNuevo2
					match( @tokenList[@numNodo].lexema )
					if @tokenList[@numNodo].lexema == ','
						match ','
						nodoNuevo3 = expresion()
						if !@hayError
							nodoNuevo1 << nodoNuevo3
						end
					end
					match ';'
				else
					@hayError = true
					@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba una cadena"
				end
				return nodoNuevo1
			end
		end

		#REGLA: bloque -> { lista-sentencias }
		def bloque(padre)
			if !@heAcabado
				if @tokenList[@numNodo].lexema == '{'
					match '{'
			        listaSentencias padre
					if @tokenList[@numNodo].lexema == '}'
						match '}'
					else
						@hayError = true
						@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba } para terminar un bloque de código"
					end
					return padre
				else
					@hayError = true
					@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba { para iniciar un bloque de código"
				end
			end
		end

		#REGLA: asignación -> identificador := expresión ;
		def asignacion()
			if !@heAcabado
				nodoId = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
				nodoIgual = nil
				match @tokenList[@numNodo].lexema
				numTemp = nil
				
				if @tokenList[@numNodo].lexema == ':='
					nodoIgual = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
					match ':='
					nodoIgual << nodoId
					temp = expresion()
					if !@hayError 
						nodoIgual << temp 
					end
				elsif @tokenList[@numNodo].lexema == '++'
					match '++'
					numTemp = @numNodo
					nodoIgual = Tree::TreeNode.new( @numNodo.to_s + ' :=', Nodo.new(':=', 'asignacion') )
					numTemp += 1
					nodoNuevo1 = Tree::TreeNode.new( numTemp.to_s + ' 1', Nodo.new('1', 'num entero') )
					numTemp += 1
					nodoNuevo2 = Tree::TreeNode.new( numTemp.to_s + ' +', Nodo.new('+', 'suma') )
					numTemp += 1
					nodoNuevo3 = Tree::TreeNode.new( numTemp.to_s + " #{nodoId.content.lexema}", Nodo.new(nodoId.content.lexema, 'id') )
					numTemp += 1
					nodoNuevo4 = Tree::TreeNode.new( numTemp.to_s + " #{nodoId.content.lexema}", Nodo.new(nodoId.content.lexema, 'id') )
					nodoIgual << nodoNuevo4
					nodoIgual << nodoNuevo2
					nodoNuevo2 << nodoNuevo3
					nodoNuevo2 << nodoNuevo1
				elsif @tokenList[@numNodo].lexema == '--'
					match '--'
					numTemp = @numNodo
					nodoIgual = Tree::TreeNode.new( @numNodo.to_s + ' :=', Nodo.new(':=', 'asignacion') )
					numTemp += 1
					nodoNuevo1 = Tree::TreeNode.new( numTemp.to_s + ' 1', Nodo.new('1', 'num entero') )
					numTemp += 1
					nodoNuevo2 = Tree::TreeNode.new( numTemp.to_s + ' -', Nodo.new('-', 'resta') )
					numTemp += 1
					nodoNuevo3 = Tree::TreeNode.new( numTemp.to_s + " #{nodoId.content.lexema}", Nodo.new(nodoId.content.lexema, "id") )
					numTemp += 1
					nodoNuevo4 = Tree::TreeNode.new( numTemp.to_s + " #{nodoId.content.lexema}", Nodo.new(nodoId.content.lexema, "id") )
					nodoIgual << nodoNuevo4
					nodoIgual << nodoNuevo2
					nodoNuevo2 << nodoNuevo3
					nodoNuevo2 << nodoNuevo1
				else
					@hayError = true
					@mensaje_error = "ERROR EN " + @tokenList[@numNodo].lexema + " línea ##{@tokenList[@numNodo].lineNumber}, se esperaba alguno de los siguientes:\n-> :=\n-> ++\n-> --\n"
				end
				
				if @tokenList[@numNodo].lexema != ';'
					@hayError = true
					@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba un punto y coma"
				else
					match ';'
				end

				if nodoIgual == nil
					return esNulo? nodoId
				else
					return nodoIgual
				end
			end
		end

		#REGLA: expresión -> expresión-simple relación expresión-simple | expresión-simple
		def expresion()
			if !@heAcabado
				nodoNuevo = expresionSimple()

				case @tokenList[@numNodo].lexema
				when "<=", "<", ">", ">=", "==", "!="
					nodo_op_rel = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
					nodo_op_rel << nodoNuevo
					match @tokenList[@numNodo].lexema
					nodoNuevo2 = expresionSimple()
					if !@hayError
						nodo_op_rel << nodoNuevo2
					end
					return nodo_op_rel
				else
					if !@hayError
						return nodoNuevo
					else
						@hayError = true
						@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba un operador relacional"
						return nodoNuevo
					end
				end
				# return nodoNuevo
			end
		end

		#REGLA: relación -> <= | < | >= | > | == | !=

		#BNF: expresión-simple -> expresión-simple suma-op termino | termino 
		#EBNF: expresión-simple -> termino { suma-op termino }
		def expresionSimple()
			if !@heAcabado
				nodoOps = nil
				nodoNuevo = term()

				if !@hayError
					while( @tokenList[@numNodo].lexema == "+" || @tokenList[@numNodo].lexema == "-" )
						aux = nodoOps
						nodoOps = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
						if aux != nil
							nodoOps << aux
						else
							nodoOps << nodoNuevo
						end
						match @tokenList[@numNodo].lexema
						nodoNuevo1 = term()
						nodoOps << nodoNuevo1
					end
				end

				if nodoOps == nil
					return nodoNuevo
				else
					return nodoOps
				end
			end
		end

		#suma-op -> + | -

		#BNF: término -> término mult-op factor | factor
		#EBNF: término -> factor { mult-op factor }
		def term()
			if !@heAcabado
				nodoOpm = nil
				nodoNuevo = factor()

				if !@hayError
					while( @tokenList[@numNodo].lexema == "*" || @tokenList[@numNodo].lexema == "/" || @tokenList[@numNodo].lexema == "%" )
						aux = nodoOpm
						nodoOpm = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
						if aux != nil
							nodoOpm << aux
						else
							nodoOpm << nodoNuevo
						end
						match @tokenList[@numNodo].lexema
						nodoNuevo1 = factor()
						nodoOpm << nodoNuevo1
					end
				end
				if nodoOpm == nil
					return nodoNuevo
				else
					return nodoOpm
				end
			end
		end


		#mult-op -> * | / | %

		#REGLA: factor -> ( expresión ) | número | identificador
		def factor()
			if !@heAcabado
				if @tokenList[@numNodo].lexema == '('
					match @tokenList[@numNodo].lexema
					nodoNuevo = expresion()
					match ')'
					return esNulo? nodoNuevo
				elsif @tokenList[@numNodo].token == 'num entero' || @tokenList[@numNodo].token == 'num real'
					nodoNuevo = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
					match @tokenList[@numNodo].lexema
					return nodoNuevo
				elsif @tokenList[@numNodo].token == 'id'
					nodoNuevo = Tree::TreeNode.new( @numNodo.to_s + ' ' + @tokenList[@numNodo].lexema, Nodo.new( @tokenList[@numNodo].lexema, @tokenList[@numNodo].token) )
					match @tokenList[@numNodo].lexema
					return nodoNuevo
				else
					@hayError = true
					@mensaje_error = "ERROR EN #{@tokenList[@numNodo].lexema} línea ##{@tokenList[@numNodo].lineNumber}, se esperaba alguno de los siguientes:\n-> Expresión\n->Numero\n->identificador\n"
					return esNulo? nil
				end
			end
		end

		def esNulo?( nodo )
			if nodo == nil
				temp = Tree::TreeNode.new( @numNodo.to_s, Nodo.new('', '') )
				return temp
			end
			return nodo
		end
	
	public
		def getRaiz()
			return @raiz
		end
end