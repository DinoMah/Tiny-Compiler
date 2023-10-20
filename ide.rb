require 'fox16'

load './src/lexic/AnalizadorLexico.rb'
load './src/sintactic/AnalizadorSintactico.rb'
load './src/semantic/AnalizadorSemantico.rb'
load './src/code_generator/code_generator.rb'
load './src/virtualMachine/VM.rb'



include Fox # Includes module funciontalities, example: Fox::FXMainWindow but you included it so you don't need "Fox::"

=begin
Check at the final of every ruby file, cause may be running something.
=end

class MenuArchivo < FXMainWindow

	attr_accessor :packer
	attr_accessor :defaultFont
=begin
	attr_accesor :codeTextArea
	attr_accesor :statusBar
	attr_accesor :menuBar
	attr_accesor :buttonsBar

	# Frames
	attr_accesor :menuBarFrame
	attr_accesor :compilerResultsFrame
	attr_accesor :programResultsFrame
	attr_accesor :codeAreaFrame

	# Fonts
	attr_accesor :codeEditorFont
	attr_accesor :windowFont

	# File vars
	attr_accesor :fileIsOpen
	attr_accesor :isNewFile
	attr_accesor :filePath
=end

	def initialize(app)
		appIcon = FXPNGIcon.new(app, File.open( "assets/img/binary.png", "rb" ).read)
		super(
			app, "Compilador Tiny",
			:width => 1200, :height => 680,
			:opts => DECOR_TITLE|DECOR_MINIMIZE|DECOR_CLOSE|DECOR_MENU|DECOR_BORDER|LAYOUT_EXPLICIT,
			:icon => appIcon,
			:miniIcon => appIcon
		)

		#Principal packer
		@packer = FXPacker.new(self, LAYOUT_FILL)
		@packer.backColor = "ghostwhite"

		# Frames
		@barraDeMenus = FXHorizontalFrame.new( @packer, :opts => LAYOUT_FILL_X|PACK_UNIFORM_HEIGHT|FRAME_NONE )
		@barraDeMenus.backColor = "ghostwhite"

		@textoYResultados = FXHorizontalFrame.new(
			@packer,
			:opts => LAYOUT_FILL_X|FRAME_THICK|PACK_UNIFORM_HEIGHT,# LAYOUT_FILL|FRAME_THICK,
		)
		# @textoYResultados.backColor = "ghostwhite"

		@consoleResults = FXHorizontalFrame.new( @packer, :opts => LAYOUT_FILL_X|FRAME_THICK|PACK_UNIFORM_HEIGHT )

		#Fonts
		@defaultFont = FXFont.new( app, "Calibri, 90, 0" )
		@editorFont = FXFont.new(app, "Consolas, 100, 0")


		# Container for textArea
		@areaDelTexto = FXPacker.new(@textoYResultados, :opts => LAYOUT_EXPLICIT, :width => 600, :height => 420)
		@areaDelTexto.backColor = "lavender"

		@textArea = FXText.new(@areaDelTexto, :opts => LAYOUT_FILL)
		initCodeEditorArea()

		@textoBarraEstado = FXStatusLine.new( @packer )
		initStatusBar()


		# menuBar = FXMenuBar.new( @barraDeMenus, :opts => LAYOUT_LEFT|FRAME_GROOVE )
		# menuBar.backColor = "lavender"

		# buttonMenu = FXMenuBar.new( @barraDeMenus, :opts => FRAME_GROOVE|LAYOUT_FILL_X )
		# buttonMenu.backColor = "lavender"


		# menuPane = FXMenuPane.new(self)
		# menuPane2 = FXMenuPane.new(self)
		buttonTabMenu = FXTabBook.new(@barraDeMenus, :opts => LAYOUT_FILL_X|FRAME_NONE, :height => 40)#|FRAME_GROOVE)
		buttonTabMenu.backColor = "lavender"
		initButtonTabMenu(app, buttonTabMenu)

		compilerResultsTabs = FXTabBook.new( @textoYResultados, :opts => LAYOUT_EXPLICIT, :width => 590, :height => 420, :x => 600 )
		compilerResultsTabs.backColor = "lavender"
		initCompilerResultsItems(compilerResultsTabs)


		programResultsTabs = FXTabBook.new( @consoleResults, :opts => LAYOUT_EXPLICIT, :width => 1190, :height => 150 )
		programResultsTabs.backColor = "lavender"
		initProgramResultsItems(programResultsTabs)

		@NUM_FILAS = 0 #Must be local for the initTable function

		# archivoMenu = FXMenuTitle.new(menuBar,"Archivo", :popupMenu=>menuPane, :opts => LAYOUT_FILL_Y|FRAME_THICK )
		# archivoMenu.backColor = "lavender"
		# archivoMenu.font = @defaultFont

		# correrMenu = FXMenuTitle.new(menuBar,"Opciones", :popupMenu=>menuPane2, :opts => LAYOUT_FILL_Y)
		# correrMenu.backColor = "lavender"
		# correrMenu.font = @defaultFont

		# initMenu(menuPane)
		# initMenu2(menuPane2)
		# initButtons(app, buttonMenu)#INICIA LOS BOTONES

		@archabierto = false
		@archivonuevo = false
		@ruta_actual = ""
		@posActual = 0

		#**********************
		@RESERVA = %w{ main if then else end do while repeat until read write float integer bool}
		@token_actual = ""
		@tipo_token = ""
		@estado_actual = ""
		@salvar = true
		@estado_actual="inicio"

		@lineaBuf = [256]
		@linea = ""
		@lineapos=0
		@buftam=0
		@auxiliar=""

		@fila=0
		@columna=0
		#**********************
	end

	def create
		super() #Calls 'create' function of FXMainWindow, neccesary for creating the window.
	end

	def initStatusBar()
		@textoBarraEstado.normalText = "Listo."
		@textoBarraEstado.font = @defaultFont
		@textoBarraEstado.backColor = "lavender"
		@textoBarraEstado.frameStyle = FRAME_GROOVE
	end

	def initCodeEditorArea()
		@textArea.font = @editorFont
		@textArea.barColumns = 4
		@textArea.disable
		@textArea.cursorColor = "magenta"
		@textArea.numberColor = "black"
		@textArea.barColor = "ghostwhite"
		@textArea.connect(SEL_KEYRELEASE) do
			posCursor()
		end
		@textArea.connect(SEL_CHANGED) do
			posCursor()
    	end
		@textArea.connect(SEL_KEYRELEASE) do
			buscar()
		end
		@textArea.styled = true

		# Color styles for each kind of token
		variables = FXHiliteStyle.from_text(@textArea)
		variables.normalForeColor = "blue"

		numbers = FXHiliteStyle.from_text(@textArea)
		numbers.normalForeColor = "goldenrod"
		numbers.style = FXText::STYLE_BOLD

		strings = FXHiliteStyle.from_text(@textArea)
		#strings.style = FXText::STYLE_BOLD
		strings.normalForeColor = "forestgreen"

		singleLineComment = FXHiliteStyle.from_text(@textArea)
		singleLineComment.normalForeColor = "lawngreen"

		multiLineComment = FXHiliteStyle.from_text(@textArea)
		multiLineComment.normalForeColor = "darkgray"

		normal = FXHiliteStyle.from_text(@textArea)
		normal.normalForeColor = "black"

		reservedWords = FXHiliteStyle.from_text(@textArea)
		reservedWords.normalForeColor = "red"
		reservedWords.style = FXText::STYLE_BOLD
		# Adding color styles to the textArea
		@textArea.hiliteStyles = [variables, numbers, strings, singleLineComment, multiLineComment, normal, reservedWords]
	end

	def initButtonTabMenu(app, buttonTabs)
		menu = FXTabItem.new(buttonTabs, "Menú")
		menu.font = @defaultFont
		menu.backColor = "lavender"
		#menu.shadowColor = 'black'
		menu.baseColor = 'lavender'
		menuButtonFrame = FXHorizontalFrame.new(buttonTabs, :opts => TAB_TOP_NORMAL)
		menuButtonFrame.backColor = 'lavender'
		menuButtonFrame.baseColor = 'lavender'
		initButtons(app, menuButtonFrame)
		# compiler = FXTabItem.new(buttonTabs, "Compilador")
		#compiler.font = @defaultFont
		#compiler.backColor = "gainsboro"
		#compilerButtonFrame = FXHorizontalFrame.new(buttonTabs, :opts => FRAME_RIDGE)
		#initButtons(app, compilerButtonFrame)
	end

	def initCompilerResultsItems(compilerResultsTabs)
		wLexico = FXTabItem.new( compilerResultsTabs, "Léxico" )
		wLexico.font = @defaultFont
		wLexico.backColor = 'lavender'
		@textoLexico = FXText.new( compilerResultsTabs, :opts => TEXT_READONLY )
		@textoLexico.text = "Aún no ha realizado un análisis."
		@textoLexico.font = @defaultFont

		wSintactico = FXTabItem.new( compilerResultsTabs, "Sintáctico" )
		wSintactico.font = @defaultFont
		wSintactico.backColor = 'lavender'
		@arbol = FXTreeList.new( compilerResultsTabs, :opts => TREELIST_NORMAL|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|LAYOUT_FILL )
		@arbol.font = @defaultFont

		wSemantico = FXTabItem.new( compilerResultsTabs, "Semántico" )
		wSemantico.font = @defaultFont
		wSemantico.backColor = 'lavender'
		@arbolConAnotacion = FXTreeList.new( compilerResultsTabs, :opts => TREELIST_NORMAL|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|LAYOUT_FILL )
		@arbolConAnotacion.font = @defaultFont

		wCodigo = FXTabItem.new( compilerResultsTabs, "Código Intermedio" )
		wCodigo.font = @defaultFont
		wCodigo.backColor = 'lavender'
		@textoCodigo = FXText.new( compilerResultsTabs, :opts => TEXT_READONLY )
		@textoCodigo.font = @defaultFont
	end

	def initProgramResultsItems(programResultsTab)
		wErrores = FXTabItem.new( programResultsTab, "Errores" )
		wErrores.font = @defaultFont
		wErrores.backColor = 'lavender'
		@textoErrores = FXText.new( programResultsTab, :opts => TEXT_READONLY )
		@textoErrores.text = "Sin errores aún."
		@textoErrores.font = @defaultFont


		wResultados = FXTabItem.new( programResultsTab, "Salida del programa" )
		wResultados.font = @defaultFont
		wResultados.backColor = 'lavender'
		@textoResultados = FXText.new(programResultsTab)
		@textoResultados.editable = false
		@textoResultados.text = "Sin resultados aún."
		@textoResultados.font = @defaultFont

		wHash = FXTabItem.new( programResultsTab, "Tabla de símbolos" )
		wHash.font = @defaultFont
		wHash.backColor = 'lavender'
		@tablaSimbolos = initTable( programResultsTab )
	end

	def initTable( area )
		tablaSimbolos = FXTable.new( area, :opts => LAYOUT_FILL )
		tablaSimbolos.editable = false
		tablaSimbolos.rowHeaderMode = LAYOUT_FIX_WIDTH
		tablaSimbolos.rowHeaderWidth = 0
		tablaSimbolos.setTableSize(0, 5)
		tablaSimbolos.font = @defaultFont
		tablaSimbolos.tableStyle |= TABLE_COL_SIZABLE
		tablaSimbolos.tableStyle |= TABLE_NO_COLSELECT
		tablaSimbolos.setColumnText(0, "Nombre Variable")
		tablaSimbolos.setColumnText(1, "Localidad")
		tablaSimbolos.setColumnText(2, "No. de línea")
		tablaSimbolos.setColumnText(3, "Valor")
		tablaSimbolos.setColumnText(4, "Tipo")
		tablaSimbolos.columnHeader.setItemJustify(0, FXHeaderItem::CENTER_X)
		tablaSimbolos.columnHeader.setItemJustify(1, FXHeaderItem::CENTER_X)
		tablaSimbolos.columnHeader.setItemJustify(2, FXHeaderItem::CENTER_X)
		tablaSimbolos.columnHeader.setItemJustify(3, FXHeaderItem::CENTER_X)
		tablaSimbolos.columnHeader.setItemJustify(4, FXHeaderItem::CENTER_X)
		tablaSimbolos.setColumnWidth( 0, 300)
		tablaSimbolos.setColumnWidth( 1, 300)
		tablaSimbolos.setColumnWidth( 2, 230)
		tablaSimbolos.setColumnWidth( 3, 219)
		tablaSimbolos.setColumnWidth( 4, 300)
		return tablaSimbolos
		# table.setItemText(2, 1, "This is a spanning item" )
		# table.setItemJustify(2, 1, FXTableItem::CENTER_X)
		#Métodos para manipular la tabla: appendRows ( ), appendColumns ( ), insertRows ( ), and insertColumns ( )
	end

	def initMenu2( menuPane2 )
		compilar = FXMenuCommand.new( menuPane2, "Compilar" )
		compilar.font = @defaultFont
		compilar.connect(SEL_COMMAND)do
			if(@ruta_actual!="")
				AnalizadorLexico.new(@ruta_actual)
				@textoErrores.text = File.open("errorLexico.txt","r").read
				@textoLexico.text = File.open("tokenLexico.txt","r").read
			end
		end
	end

	def initMenu(menuPane)

		abrir = FXMenuCommand.new(menuPane,"Abrir")
		abrir.font = @defaultFont
		abrir.connect(SEL_COMMAND) do
			abreArchivo()
		end

		nuevo = FXMenuCommand.new(menuPane,"Nuevo")
		nuevo.font = @defaultFont
		nuevo.connect(SEL_COMMAND) do |sender, sel, ptr|
			if @archabierto==false
				@textArea.text = ""
				@textArea.enable
				@archabierto = true
				@archivonuevo = true
			end
		end

		guardar = FXMenuCommand.new(menuPane,"Guardar")
		guardar.font = @defaultFont
		guardar.connect(SEL_COMMAND) do
			metodoGuardar()
		end

		guardarComo = FXMenuCommand.new(menuPane,"Guardar como")
		guardarComo.font = @defaultFont
		guardarComo.connect(SEL_COMMAND) do |sender, sel, ptr|
			metodoGuardarComo()
		end

		cerrar = FXMenuCommand.new(menuPane,"Cerrar")
		cerrar.font = @defaultFont
		cerrar.connect(SEL_COMMAND) do
			@archabierto = false
			@archivonuevo = false
			@textArea.text = ""
			@textoErrores.text = ""
			@textoLexico.text = ""
			@ruta_actual = ""
			@textArea.disable
		end

		salir = FXMenuCommand.new(menuPane, "Salir")
		salir.font = @defaultFont
		salir.connect(SEL_COMMAND) do
			self.close
		end
	end

	def abreArchivo()
		if @archabierto==false
			dialogo = FXFileDialog.new(self, "Abrir Archivo")
			dialogo.selectMode = SELECTFILE_EXISTING
			dialogo.patternList = ["*.txt","*.rb"]
			if dialogo.execute != 0
				@ruta_actual="#{dialogo.filename}"
				@archabierto=true
        			s = File.open(dialogo.filename,"r", encoding: 'ISO-8859-1:UTF-8').read
        			s.encoding
				@textArea.text = s
				@textArea.enable
        			buscar()
			end
		end
	end

	def metodoGuardar()
		if @archabierto==true
      if @archivonuevo==false
				File.open(@ruta_actual,"w") { |f|
					f.puts @textArea.text
				}
			end
		elsif @archivonuevo == true
          	archguardar = FXFileDialog.getSaveFilename(self, "Guardar como", ".txt", "*.txt")
			@ruta_actual = archguardar
			if guardarArchivo(@textArea.text, archguardar)
				@archivonuevo = false
				popMessage = FXMessageBox.new(self, "Mensaje:", "Guardado exitoso",nil, MBOX_OK|DECOR_TITLE|DECOR_BORDER, self.x, self.y)
				popMessage.execute
			end
		end
	end


	def metodoGuardarComo()
		if @archabierto==true
			archguardar = FXFileDialog.getSaveFilename(self, "Guardar como", ".txt", "*.txt")
			@ruta_actual = archguardar
			if guardarArchivo(@textArea.text,archguardar)
				@archivonuevo=false
				popMessage = FXMessageBox.new(self, "Mensaje:", "Guardado exitoso",nil, MBOX_OK|DECOR_TITLE|DECOR_BORDER, self.x, self.y)
				popMessage.execute
			end
		end
	end

	def guardarArchivo(contenido,nombre)
		begin
			file = File.new(nombre,"wb")
			file.print contenido;
			file.close;
			puts "> Guardado exitoso."
			return true;
		rescue
			puts "> Guardado fallido: archivo no encontrado."
			return false
		end
	end


	def initButtons(app, menuBar)
		iconsPath = 'assets/img/'
		#Iconos que van a usar los botones
		iNuevo = FXPNGIcon.new(app, File.open("#{iconsPath}new_button.png", "rb").read )
		iGuardar = FXPNGIcon.new(app, File.open("#{iconsPath}save_button.png", "rb").read )
		saveAsIcon = FXPNGIcon.new(app, File.open("#{iconsPath}SaveAsIcon.png").read)
		iCerrar = FXPNGIcon.new(app, File.open("#{iconsPath}close_button.png", "rb").read )
		iCompilar = FXPNGIcon.new(app, File.open("#{iconsPath}compile_button.png", "rb").read )
		iAbrir = FXPNGIcon.new(app, File.open("#{iconsPath}open_button.png", "rb").read )
		infoIcon = FXPNGIcon.new(app, File.open("#{iconsPath}infoIcon.png", "rb").read )

		FXToolTip.new(app) #Pequeña descripción del botón al dejar el cursor arriba

		bAbrir = FXButton.new(menuBar, "\tAbrir", :opts => FRAME_LINE|BUTTON_TOOLBAR )
		bAbrir.icon = iAbrir
		bAbrir.backColor = "lavender"
		bAbrir.connect(SEL_COMMAND) do
			abreArchivo()
		end

		bNuevo = FXButton.new(menuBar, "\tNuevo", :opts => FRAME_LINE|BUTTON_TOOLBAR )
		bNuevo.icon = iNuevo
		bNuevo.backColor = "lavender"
		bNuevo.connect(SEL_COMMAND) do
			if (@archabierto == false)
				@textArea.text = ""
				@textArea.enable
				@archabierto = true
				@archivonuevo = true
			end
		end

		bGuardar = FXButton.new(menuBar, "\tGuardar", :opts => FRAME_LINE|BUTTON_TOOLBAR )
		bGuardar.icon = iGuardar
		bGuardar.backColor = "lavender"
		bGuardar.connect(SEL_COMMAND) do
			metodoGuardar()
		end

		saveAsButton = FXButton.new(menuBar, "\tGuardar Como...", :opts => FRAME_LINE|BUTTON_TOOLBAR)
		saveAsButton.icon = saveAsIcon
		saveAsButton.backColor = 'lavender'
		saveAsButton.connect(SEL_COMMAND) do
			self.metodoGuardarComo
		end

		bCerrar = FXButton.new(menuBar, "\tCerrar", :opts => FRAME_LINE|BUTTON_TOOLBAR )
		bCerrar.icon = iCerrar
		bCerrar.backColor = "lavender"
		bCerrar.connect(SEL_COMMAND) do
			@archabierto = false
      		@archivonuevo = false
      		@textoErrores.text = ""
      		@textoLexico.text = ""
			@textArea.text = ""
			@textoCodigo.text = ""
			@ruta_actual = ""
			@textArea.disable
			# @programResultsTabs.backColor = "lavender"
		end

		FXSeparator.new(menuBar, :opts => SEPARATOR_NONE|LAYOUT_FILL_X)

		bCompilar = FXButton.new(menuBar, "\tCompilar", :opts => FRAME_LINE|BUTTON_TOOLBAR )
		bCompilar.icon = iCompilar
		bCompilar.backColor = "lavender"
		bCompilar.connect(SEL_COMMAND) do
			if( @ruta_actual != "" )
				AnalizadorLexico.new( @ruta_actual )
				@textoErrores.text = ""
				if( !File.zero?("errorLexico.txt") )
					@textoErrores.text = File.open( "errorLexico.txt", "r" ).read
				end

				@textoLexico.text = File.open( "tokenLexico.txt", "r" ).read
				sintacticAnalyzer = AnalizadorSintactico.new(@ruta_actual)
				if( !File.zero?("Datos/errores_sintacticos.txt") )
			      	@textoErrores.text += "\nERRORES SINTÁCTICOS: \n"
					@textoErrores.text += File.open( "Datos/errores_sintacticos.txt", "r").read
				end
				crearArbolGrafico( sintacticAnalyzer.getRaiz, @arbol )
				# #=================================================================================================

				a_c = AnalizadorSemantico.new( sintacticAnalyzer.getRaiz.detached_subtree_copy, @ruta_actual )

				if( !File.zero?("Datos/errores_semanticos.txt") )
				 	@textoErrores.text += "\nERRORES SEMÁNTICOS: \n"
					@textoErrores.text += File.open("Datos/errores_semanticos.txt", "r").read
				end
				crearArbolGrafico( a_c.getRaiz, @arbolConAnotacion )
				addTableEntries( a_c.getSymTab )

				if (File.zero?('Datos/errorLexico.txt') && File.zero?('Datos/errores_sintacticos.txt') && File.zero?('Datos/errores_semanticos.txt'))
					codeGenerator = CodeGenerator.new sintacticAnalyzer.getRaiz

					codeGenerator.syntaxTree.children do |treeNode|
						codeGenerator.genCode treeNode
					end

					if !File.zero? 'Datos/assemblies.txt'
						File.write 'Datos/assemblies.txt', 'stp', mode: 'a'
						@textoCodigo.text = File.open('Datos/assemblies.txt', 'r').read
					end

					virtualMachine = VirtualMachine.new a_c.getSymTab, self
					virtualMachine.init
				else
					FXMessageBox.warning self, MBOX_OK, 'Warning!', 'Solve every error before trying to run the program (:'
				end
			end
		end

		infoButton = FXButton.new(menuBar, "\tInfo", :opts => FRAME_LINE|BUTTON_TOOLBAR|LAYOUT_RIGHT)
		infoButton.icon = infoIcon
		infoButton.backColor = 'lavender'
		infoButton.connect(SEL_COMMAND) do
			infoButtonAction()
		end
	end

	def infoButtonAction()
		popMessage = FXMessageBox.new(
			self, "Información:", "Autor: \n   Juan Carlos Herrera\nLicencia:\nSolo propósitos educacionales",
			nil, MBOX_OK|DECOR_TITLE|DECOR_BORDER,
		)
		popMessage.width = 200
		popMessage.height = 150
		popMessage.execute
	end

	def posCursor()
		fil = col = 1
		if(@archabierto)
			if(fil != @textArea.getCursorRow()+1 || col != @textArea.getCursorColumn()+1)
				fil = @textArea.getCursorRow()+1
				col = @textArea.getCursorColumn()+1
			end
			@textArea.helpText = "#{fil}:#{col}"
		end
	end

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
	# All this is for textarea highlight
	def buscar()
		@cont = 0
		@estado_actual = "inicio"
		@en_cadena = false
		@reservado = []
		@id_actual = ""
		@vector = @textArea.text.scan(/.|\s/)

		for i in 0..@vector.length-1
			if(@estado_actual!="id")
				@id_actual=""
			end
			token(@vector[i])

			if(@vector[i]=='"' && @en_cadena)
				@en_cadena=false
			end

			if(@estado_actual=="inicio")
				if(/[a-zA-Z]|Ñ|ñ/.match(@vector[i]))
					@estado_actual="id"
				elsif(/[0-9]/.match(@vector[i]))
					@estado_actual="num"
				elsif(@vector[i]=='"')
					@estado_actual="cadena"
					@en_cadena=true
				elsif(@vector[i]=='/')
					@estado_actual="div"
				else
					@estado_actual="NoPintar"
				end
			end

			if(@estado_actual=="id")
				if(@vector[i]=="Ñ" || @vector[i]=="ñ")
					puts "Entra"
					@textArea.changeStyle(@cont,1,1)
					@cont+=1
				else
					@textArea.changeStyle(@cont,1,1)
				end
				@id_actual+=@vector[i]

				if(@id_actual=="main" || @id_actual=="if" || @id_actual=="then" || @id_actual=="else" || @id_actual=="end" || @id_actual=="do" || @id_actual=="while" || @id_actual=="repeat" || @id_actual=="until" || @id_actual=="read" || @id_actual=="write" || @id_actual=="float" || @id_actual=="integer" || @id_actual=="bool")
					@textArea.changeStyle(@cont-(@id_actual.length-1),@id_actual.length,7)
				else
					@textArea.changeStyle(@cont-(@id_actual.length-1),@id_actual.length,1)
				end
				@reservado[i]=true
			end

			if(@estado_actual=="num")
				@textArea.changeStyle(@cont,1,2)
			end

			if(@estado_actual=="cadena")
				if(@vector[i]=="Ñ" || @vector[i]=="ñ")
					@textArea.changeStyle(@cont,1,3)
					@cont +=1
				else
					@textArea.changeStyle(@cont,1,3)
				end
				@textArea.changeStyle(@cont,1,3)
			end

			if(@estado_actual=="com_lin")
				if(@vector[i]=="Ñ" || @vector[i]=="ñ")
					@textArea.changeStyle(@cont,1,4)
					@cont+=1
				else
					@textArea.changeStyle(@cont,1,4)
				end
				@textArea.changeStyle(@cont,1,4)
			end

			if(@estado_actual=="com_mul_lin" || @estado_actual=="term_com")
				if(@vector[i]=="Ñ" || @vector[i]=="ñ")
					@textArea.changeStyle(@cont,1,5)
					@cont+=1
				else
					@textArea.changeStyle(@cont,1,5)
				end
				@textArea.changeStyle(@cont,1,5)
			end

			if(@estado_actual=="NoPintar" || @estado_actual=="div")
				@textArea.changeStyle(@cont, 1, 6)
			end

			if(@vector[i]=="¿")
				@cont+=1
			elsif(@vector[i]=="¨")
				@cont+=1
			elsif(@vector[i]=="°")
				@cont+=1
			elsif(@vector[i]=="¬")
				@cont+=1
			elsif(@vector[i]=="¡")
				@cont+=1
			elsif(@vector[i]=="á")
				@cont+=1
			elsif(@vector[i]=="é")
				@cont+=1
			elsif(@vector[i]=="í")
				@cont+=1
			elsif(@vector[i]=="ó")
				@cont+=1
			elsif(@vector[i]=="ú")
				@cont+=1
			elsif(@vector[i]=="Á")
				@cont+=1
			elsif(@vector[i]=="É")
				@cont+=1
			elsif(@vector[i]=="Í")
				@cont+=1
			elsif(@vector[i]=="Ó")
				@cont+=1
			elsif(@vector[i]=="Ú")
				@cont+=1
			elsif(@vector[i]=="´")
				@cont+=1
			end
			#puts "#{@estado_actual}/#{@cont}"
			@cont+=1
		end
	end

	def token(c)
		case @estado_actual
			when "id"
				if( !(/\w|Ñ|ñ/.match(c)) )
					@estado_actual = "inicio"
				end
			when "num"
				if(!(/[0-9]/.match(c)))
					@estado_actual="inicio"
				end
			when "cadena"
				if(!@en_cadena)
					@estado_actual="inicio"
				end
			when "div"
				if(c=='/')
					@estado_actual="com_lin"
					@textArea.changeStyle(@cont-1,1,4)
				elsif(c=='*')
					@estado_actual="com_mul_lin"
					@textArea.changeStyle(@cont-1,1,5)
				else
					@estado_actual="inicio"
				end
			when "com_lin"
				if(c=="\n")
					@estado_actual="inicio"
				end
			when "com_mul_lin"
				if(c=='*')
					@estado_actual="term_com"
				end
			when "term_com"
				if(c=='/')
					@textArea.changeStyle(@cont,1,5)
					@estado_actual="noTomar"
				elsif (c!='*')
					@estado_actual="com_mul_lin"
				end
			when "noTomar"
				@estado_actual="inicio"
			else
				@estado_actual="inicio"
		end
	end

	def crearArbolGrafico( raiz, arbol )
		arbol.clearItems
		raiz.each{ |nodoActual|
			actual = FXTreeItem.new( nodoActual.content.lexema, nil, nil, nodoActual.name )
			if nodoActual.parent == nil
				arbol.appendItem( nil, actual )
			else
				padre = arbol.findItemByData( nodoActual.parent.name )
				arbol.appendItem( padre, actual )
				arbol.expandTree( padre )
			end
		}
	end

	# End of textArea highlights

	def addTableEntries( symTab )
		@tablaSimbolos.clearItems
		@tablaSimbolos.rowHeaderMode = LAYOUT_FIX_WIDTH
		@tablaSimbolos.rowHeaderWidth = 0
		@tablaSimbolos.setTableSize(0, 5)
		@tablaSimbolos.font = @defaultFont
		@tablaSimbolos.tableStyle |= TABLE_COL_SIZABLE
		@tablaSimbolos.setColumnText(0, "Nombre Variable")
		@tablaSimbolos.setColumnText(1, "Localidad")
		@tablaSimbolos.setColumnText(2, "No. de línea")
		@tablaSimbolos.setColumnText(3, "Valor")
		@tablaSimbolos.setColumnText(4, "Tipo")
		@tablaSimbolos.columnHeader.setItemJustify(0, FXHeaderItem::CENTER_X)
		@tablaSimbolos.columnHeader.setItemJustify(1, FXHeaderItem::CENTER_X)
		@tablaSimbolos.columnHeader.setItemJustify(2, FXHeaderItem::CENTER_X)
		@tablaSimbolos.columnHeader.setItemJustify(3, FXHeaderItem::CENTER_X)
		@tablaSimbolos.columnHeader.setItemJustify(4, FXHeaderItem::CENTER_X)
		@tablaSimbolos.setColumnWidth( 0, 300)
		@tablaSimbolos.setColumnWidth( 1, 300)
		@tablaSimbolos.setColumnWidth( 2, 230)
		@tablaSimbolos.setColumnWidth( 3, 219)
		@tablaSimbolos.setColumnWidth( 4, 300)
		@NUM_FILAS = 0
		symTab.each{ |llave, entrada|
			@tablaSimbolos.appendRows(1)
			@tablaSimbolos.setItemText(@NUM_FILAS, 0, symTab[llave].nombre)
			@tablaSimbolos.setItemText(@NUM_FILAS, 1, symTab[llave].direccionMem.to_s)
			@tablaSimbolos.setItemText(@NUM_FILAS, 2, symTab[llave].numsLinea)
			@tablaSimbolos.setItemText(@NUM_FILAS, 3, symTab[llave].valor.to_s)
			@tablaSimbolos.setItemText(@NUM_FILAS, 4, symTab[llave].tipo)
			@tablaSimbolos.setItemJustify(@NUM_FILAS, 0, FXTableItem::CENTER_X)
			@tablaSimbolos.setItemJustify(@NUM_FILAS, 1, FXTableItem::CENTER_X)
			@tablaSimbolos.setItemJustify(@NUM_FILAS, 2, FXTableItem::CENTER_X)
			@tablaSimbolos.setItemJustify(@NUM_FILAS, 3, FXTableItem::CENTER_X)
			@tablaSimbolos.setItemJustify(@NUM_FILAS, 4, FXTableItem::CENTER_X)
			@NUM_FILAS += 1
		}
	end
end

app = FXApp.new
m = MenuArchivo.new(app)
app.create
m.show(PLACEMENT_SCREEN)
app.run
