class AnalizadorLexico
     public def getTokens()
          return @tokens
     end

     private
          attr_accessor :tokens
          attr_accessor :token_struct

          def initialize(ruta)
               @tokens = []
               @token_struct = Struct.new(:token, :type)
               @ESTADOS = %w{ inicio id num real com_igual com_dif asignaIgual div com_lin com_mul_lin term_com suma inc resta dec mayor menor may_igual men_igual parentesis_abre parentesis_cierra llave_abre llave_cierra multiplicacion punto_y_coma coma enAsignacionNum enAsignacionIDA cadena hecho }
               @RESERVA = %w{ main if then else end do while repeat until read write float integer bool }
               @lectura = true
               @token_actual = ""
               @tipo_token = ""
               @estado_actual = ""
               @salvar = true

               @lineaBuf = [256]
               @linea = ""
               @lineapos = 0
               @buftam = 0
               @auxiliar = ""

               @fila = 0
               @columna = 0

               @archivo = File.open( ruta, 'r' )
               @arch_error = File.open( "errorLexico.txt", 'w' )
               @arch_token = File.open( "tokenLexico.txt", 'w' )

               while( !@finArchivo )
                    token()
                    if( @estado_actual == "hecho" && @token_actual != "" )
                         if( @tipo_token == "id" )
                              palabrasReservadas( @token_actual )
                         end
                         # print "#{@tipo_token}-> #{@token_actual}"
                         if( @tipo_token == "Error" )
                              print " fil:#{@fila}, col:#{@lineapos+2}"
                              @tokens.push(@token_struct.new(@tipo_token, @token_actual))
                              @arch_error.puts("#{@tipo_token}-> #{@token_actual} fil:#{@fila}, col:#{@lineapos+2}") # TODO: This will be removed
                         else
                              @tokens.push(@token_struct.new(@tipo_token, @token_actual))
                              @arch_token.puts("#{@tipo_token}-> #{@token_actual}") # TODO: This will be removed
                         end
                         # print "\n"
                         if( @auxiliar != "" )
                              print "Error-> #{@auxiliar}"
                              print " fil:#{@fila}, col:#{@lineapos+2}"
                              @arch_error.puts("Error-> #{@auxiliar} fil:#{@fila}, col:#{@lineapos+2}")
                              @auxiliar=""
                              print "\n"
                         end
                    end
               end
               @archivo.close
               @arch_error.close
               @arch_token.close
          end

          def palabrasReservadas(id)
               @RESERVA.each do |palabra|
                    if( palabra == id)
                         @tipo_token = "palabra reservada"
                         break
                    end
               end
          end

          def tomarCaracter()
               if( !(@lineapos < (@buftam - 1)) )
                    if( @linea = @archivo.gets )
                         i = 0
                         while( i < 256 )
                              @lineaBuf[i] = ""
                              i = i + 1
                         end
                         @lineapos = 0
                         @buftam = @linea.length
                         i = 0
                         @linea.each_char{ |c|
                              @lineaBuf[i] = c
                              i = i + 1
                         }
                         @fila = @fila + 1
                         return @lineaBuf[@lineapos]
                    else
                         @finArchivo = true
                         return "fA"
                    end
               else
                    @lineapos = @lineapos + 1
                    return @lineaBuf[@lineapos]
               end
          end

          def noTomarCaracter()
               if( !@finArchivo )
                    @lineapos = @lineapos - 1
               end
          end

          def token()
               @estado_actual = "inicio"
               @token_actual = ""
               while( @estado_actual != "hecho" )
                    c = tomarCaracter()
                    @salvar = true
                    if( c == "fA" )
                         @salvar = false
                         @finArchivo = true
                         ultimoToken()
                         @estado_actual = "hecho"
                    end
                    case @estado_actual
                         when "inicio"
                              if(/[a-zA-Z]/.match(c))
                                   @estado_actual="id"
                              elsif(/[0-9]/.match(c))
                                   @estado_actual="num"
                              elsif(c=='"')
                                   @estado_actual="cadena"
                                   @salvar=false
                                   #puts "Cadena:#{c}"
                              elsif((c==" ") || (c=="\t") || (c=="\n"))
                                   @salvar=false
                              elsif(c=='=' || c=='!' || c==':')
                                   @estado_actual="enAsignacionIDA"
                              elsif(c=='/')
                                   @estado_actual="div"
                                   #puts "Division:#{c}"
                              elsif(c=='+')
                                   @estado_actual="suma"
                                   #puts "Suma:#{c}"
                              elsif(c=='-')
                                   @estado_actual="resta"
                                   #puts "Resta:#{c}"
                              elsif(c=='<')
                                   @estado_actual="menor"
                                   #puts "Menor:#{c}"
                              elsif(c=='>')
                                   @estado_actual="mayor"
                                   #puts "Mayor:#{c}"
                              else
                                   @estado_actual="hecho"
                                   case c
                                        when '%'
                                             @tipo_token="residuo"
                                             #puts "Residuo:#{c}"
                                        when '('
                                             @tipo_token="paretesis abre"
                                             #puts "Paretesis abre:#{c}"
                                        when ')'
                                             @tipo_token="parentesis cierra"
                                             #puts "Parentesis cierra:#{c}"
                                        when '{'
                                             @tipo_token="llave abre"
                                             #puts "Llave abre:#{c}"
                                        when '}'
                                             @tipo_token="llave cierra"
                                             #puts "Llave cierra:#{c}"
                                        when '*'
                                             @tipo_token="multiplicacion"
                                             #puts "Multiplicacion:#{c}"
                                        when ';'
                                             @tipo_token="punto y coma"
                                             #puts "Punto coma:#{c}"
                                        when ','
                                             @tipo_token="coma"
                                             #puts "Coma:#{c}"
                                        else
                                             @tipo_token="Error"
                                   end
                              end
                    when "id"
                         if(/\w|ñ|Ñ/.match(c))#/\w/.match(c) => identifica si c es letra, digito o guion bajo (_)
                              @salvar=true
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="id"
                         end
                    when "num"
                         if(/[0-9]/.match(c))
                              @salvar=true
                         else
                              if (c==".")
                                   if (/[0-9]/.match(@lineaBuf[@lineapos+1]))
                                        @estado_actual="enAsignacionNum"
                                   else
                                        @estado_actual="hecho"
                                        @salvar=false
                                        @tipo_token="num entero"
                                        @auxiliar="."
                                   end
                              else
                                   noTomarCaracter()
                                   @estado_actual="hecho"
                                   @salvar=false
                                   @tipo_token="num entero"
                              end
                         end
                    when "real"
                         if( /[0-9]/.match(c) )
                              @salvar=true
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="num real"
                         end
                    when "enAsignacionNum"
                         if( /[0-9]/.match(c) )
                              @estado_actual="real"
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="Error"
                         end
                    when "enAsignacionIDA"
                         if(c=='=')
                              if(@token_actual=='=')
                                   @tipo_token="com_igual"
                                   #@estado_actual="com_igual"
                              elsif(@token_actual=='!')
                                   @tipo_token="com_dif"
                                   #@estado_actual="com_dif"
                              else
                                   @tipo_token="asignacion"
                                   #@estado_actual="asignaIgual"
                              end
                         else
                              noTomarCaracter()
                              @salvar=false
                              @tipo_token="Error"
                         end
                         @estado_actual="hecho"
                    when "div"
                         if(c=='/')
                              @estado_actual="com_lin"
                         elsif(c=='*')
                              @estado_actual="com_mul_lin"
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="div"
                         end
                    when "com_lin"
                         if(c=="\n")
                              @token_actual=""
                              @estado_actual="hecho"
                         end
                         @salvar=false
                    when "com_mul_lin"
                         if(c=='*')
                              #puts "term_com"
                              @estado_actual="term_com"
                         end
                         @salvar=false
                    when "term_com"
                         if(c=='/')
                              @token_actual=""
                              @estado_actual="hecho"
                         elsif (c!='*')
                              @estado_actual="com_mul_lin"
                         end
                         @salvar=false
                    when "suma"
                         if(c=='+')
                              @tipo_token="inc"
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="suma"
                         end
                         @estado_actual="hecho"
                    when "resta"
                         if(c=='-')
                              @tipo_token="dec"
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="resta"
                         end
                         @estado_actual="hecho"
                    when "mayor"
                         if(c=='=')
                              @tipo_token="may_igual"
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="mayor"
                         end
                         @estado_actual="hecho"
                    when "menor"
                         if(c=='=')
                              @tipo_token="men_igual"
                         else
                              noTomarCaracter()
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="menor"
                         end
                         @estado_actual="hecho"
                    when "cadena"
                         if(c=='"')
                              @estado_actual="hecho"
                              @salvar=false
                              @tipo_token="cadena"
                         end
                    end
               
                    if(@salvar)
                         @token_actual+=c
                    end
               end
          end

          def ultimoToken()
               case @estado_actual
                    when "id"
                         @tipo_token = "id"
                    when "num"
                         @tipo_token = "num entero"
                    when "real"
                         @tipo_token = "num real"
                    when "cadena"
                         @tipo_token = "cadena"
                    when "com_lin"
                         @tipo_token = @token_actual= ""
                    when "com_mul_lin"
                         @tipo_token = @token_actual = ""
                    else
                         @tipo_token = "Error"
               end
          end
end

ruta = ARGV[0]
if(ruta!=nil)
     AnalizadorLexico.new(ruta)
end

