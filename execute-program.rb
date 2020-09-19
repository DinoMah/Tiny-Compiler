load './src/lexic/AnalizadorLexico.rb'
load './src/sintactic/AnalizadorSintactico.rb'
load './src/semantic/AnalizadorSemantico.rb'

puts '¡Bienvenido al compilador Tiny!'
print 'Para empezar dame un archivo de código Tiny (puedes arrastrar el archivo a la consola): '
archivo = gets.chomp! # Obtiene el input y quita el saldo de línea del input recibido
ruta = ""
for i in 1...archivo.length-1
    ruta += archivo[i] # Quitamos las dobles comillas al principio y al final
end
ruta.gsub!(/\\/, '/') # Cambia el formato de ruta de Windows a tipo Linux
tokens  = AnalizadorLexico.new(ruta)

# Sí no hay errores de ningún tipo va a continuar con la siguiente etapa del análisis
if File.zero? "errorLexico.txt"
    analizadorSintactico = AnalizadorSintactico.new(ruta)
    analizadorSintactico.getRaiz().print_tree
    if File.zero? "Datos/errores_sintacticos.txt"
        analizadorSemantico = AnalizadorSemantico.new analizadorSintactico.getRaiz(), ruta
        # analizadorSemantico.showSymTab
        # analizadorSemantico.getRaiz().print_tree
        # e = tokens.getTokens()
        # e.each do |i|
        #     puts "#{i.token}, #{i.type}"
        # end
    end
end
