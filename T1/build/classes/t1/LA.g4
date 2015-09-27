
grammar LA;

@members {
   public static String grupo="<<551740>>";
   PilhaDeTabelas pilhaDeTabelas = new PilhaDeTabelas();
   TabelaDeSimbolos TabelaDeTipos = new TabelaDeSimbolos("tipos");
   PilhaDeTabelas TabelasDeRegistros = new PilhaDeTabelas();
   String error="";
}

ALGORITMO: 'algoritmo';

FIM_ALGORITMO :'fim_algoritmo';
	
DECLARE : 'declare';

CONSTANTE : 'constante';

TIPO : 'tipo';

DOISPONTOS : ':';	

ABRECOLCHETES :	'[';

FECHACOLCHETES : ']';

VIRGULA	: ',';

EXPOENTE : '^';
	
PONTO :	'.';
	
LITERAL : 'literal';

INTEIRO	: 'inteiro';

REAL : 'real';	

LOGICO: 'logico';

VERDADEIRO : 'verdadeiro';

FALSO : 'falso';

REGISTRO : 'registro';

FIM_REGISTRO : 'fim_registro';

PROCEDIMENTO : 'procedimento';

FIM_PROCEDIMENTO : 'fim_procedimento';

ABREPARENTESE : '(';

FECHAPARENTESE : ')';

FUNCAO : 'funcao';

FIM_FUNCAO : 'fim_funcao';

VAR : 'var';

LEIA : 'leia';

ESCREVA : 'escreva';

SE : 'se';

ENTAO : 'entao';

FIM_SE : 'fim_se';

SENAO : 'senao';	

CASO : 'caso';

SEJA : 'seja';	

FIM_CASO : 'fim_caso';

PARA : 'para';

ATRIBUICAO : '<-';

ATE : 'ate';

FACA : 'faca';

FIM_PARA : 'fim_para';

ENQUANTO : 'enquanto';

FIM_ENQUANTO : 'fim_enquanto';

RETORNE : 'retorne';	

PONTOPONTO : '..';

MULTIPLICACAO : '*';

MENORIGUAL : '<=';

DIVISAO : '/' ;

MAIORIGUAL : '>=';

PORCENTAGEM : '%';

MENOR : '<';

MAIOR : '>';

IGUAL : '=';

DIFERENTE : '<>';

OU : 'ou';

E : 'e';

NAO : 'nao';

SOMA: '+';

SUBTRACAO : '-';

OPERADOR_E : '&';

// Sequencia de caracteres entre aspas dupla de apenas uma linha
CADEIA : '\'' ~('\n' | '\r' | '\'')* '\'' | '"' ~('\n' | '\r' | '"')* '"';

// Sequencia de letras, dígitos e underscore, começando por letra ou underscore
IDENT : ('_'|'a'..'z'|'A'..'Z')('a'..'z'|'A'..'Z'|'_'|'0'..'9')*;

// Sequencia de diígitos
NUM_INT : ('0'..'9')+;

// Pelo menos um dígito seguido de um ponto decimal e de uma sequência de um ou mais dígitos
NUM_REAL : ('0'..'9')+ '.' ('0'..'9')+;

//Espa�os em branco IGNORADOS pelo analisador l�xico.
WS : ( ' ' |'\t' | '\r' | '\n') {skip();}; 

//coment�rios curtos IGNORADOS pelo analisador l�xico.
COMENTARIO : '{' ~('\n'|'\r'|'\t')* '\r'? '\n'? '}'('\n'('\n'|'\t'))* {skip();};

// Analisador Sintático

programa : { pilhaDeTabelas.empilhar(new TabelaDeSimbolos("global"));
             TabelaDeTipos.adicionarSimbolo("literal", "literal");
             TabelaDeTipos.adicionarSimbolo("inteiro", "inteiro");
             TabelaDeTipos.adicionarSimbolo("real", "real");
             TabelaDeTipos.adicionarSimbolo("logico", "logico");
             
            }
           declaracoes ALGORITMO corpo FIM_ALGORITMO
           { 
             pilhaDeTabelas.desempilhar();
             if(error!="")throw new RuntimeException(error);
           }
         ;

declaracoes : decl_local_global declaracoes 
            |
            ;

decl_local_global : decl_local
                  | declaracao_global
                  ;

decl_local : DECLARE variavel
             {
                 for (String s : $variavel.nomes){
                    if(pilhaDeTabelas.topo().existeSimbolo(s))
                        error += "Linha " + $variavel.linha + ": identificador "+s+" ja declarado anteriormente\n" ;
                        //error+=pilhaDeTabelas.topo().getEscopo();

                    else{
                        if(TabelaDeTipos.existeSimbolo($variavel.tipoSimbolo)){
                            pilhaDeTabelas.topo().adicionarSimbolo(s, $variavel.tipoSimbolo);
                            if(TabelasDeRegistros.existeTabela($variavel.tipoSimbolo)!=null)
                            {
                               TabelaDeSimbolos tabela_registro = TabelasDeRegistros.existeTabela($variavel.tipoSimbolo);
                               for (String t : tabela_registro.getSimbolos())
                               {
                                pilhaDeTabelas.topo().adicionarSimbolo(s+t, $variavel.tipoSimbolo);
                               }
                             }
                            
                        }
                        else{
                            error += "Linha " + $variavel.linha + ": tipo "+$variavel.tipoSimbolo+" nao declarado\n" ;
                            pilhaDeTabelas.topo().adicionarSimbolo(s, $variavel.tipoSimbolo);
                            }

                        
                    }
                }
            }
             
             
           | CONSTANTE v1=IDENT DOISPONTOS v2=tipo_basico IGUAL valor_constante
             {
              if(pilhaDeTabelas.topo().existeSimbolo($v1.getText()))
                  error += "Linha " + $v1.getLine() + ": identificador "+$v1.getText()+" ja declarado anteriormente\n" ;
              else
                  pilhaDeTabelas.topo().adicionarSimbolo($v1.getText(), $v2.tipoSimbolo);
              }
           | TIPO v1=IDENT DOISPONTOS v3=tipo[$v1.getText()]
             {
              if(pilhaDeTabelas.topo().existeSimbolo($v1.getText()))
                  error += "Linha " + $v1.getLine() + ": identificador "+$v1.getText()+" ja declarado anteriormente\n" ;
              else{
                  pilhaDeTabelas.topo().adicionarSimbolo($v1.getText(), $v3.tipoSimbolo);
                  TabelaDeTipos.adicionarSimbolo($v1.getText(), $v3.tipoSimbolo);
              }
              }
           ;



variavel returns[ List<String> nomes, String tipoSimbolo, int linha ]
@init { $nomes = new ArrayList<String>(); $tipoSimbolo=""; $linha=-1; }
    : v1=IDENT dimensao v2=mais_var DOISPONTOS v3=tipo[$tipoSimbolo] 
      {    
           int i=0;
           $tipoSimbolo = $v3.tipoSimbolo;
          // error+="Tipo da variável: " + $v3.tipoSimbolo;
           $nomes.add($v1.getText());
           $nomes.addAll($v2.nomes);
           if($v2.linha==-1)
               $linha = $v1.getLine();
           else
               $linha = $v2.linha;
               
           
          
      }
    ;

mais_var returns[ List<String> nomes, int linha ]
    @init { $nomes = new ArrayList<String>(); $linha=-1; }
    : (VIRGULA v1=IDENT
       {
         if(!pilhaDeTabelas.existeSimbolo($v1.getText())){
            $nomes.add($v1.getText());
            $linha = $v1.getLine();
         }
         else{
              error+="Linha " + $v1.getLine() + ": identificador " + $v1.getText() + " ja declarado anteriormente\n";
         }
        
       } dimensao)*
    ;

identificador returns [ String txt, int linha ] 
    :   { $txt = ""; $linha=-1;}
        ponteiros_opcionais v1=IDENT {$txt += $v1.text; $linha = $v1.getLine(); } dimensao oi=outros_ident {$txt += $oi.txt; }
                
              ;

ponteiros_opcionais : EXPOENTE*
                    ;

outros_ident returns [ String txt ]
@init {$txt="";}
    : PONTO id=identificador { $txt = "."+$id.txt; }
             |
             ;
	
dimensao : (ABRECOLCHETES exp_aritmetica FECHACOLCHETES)*
         ;

tipo[String tipo_registro] returns [String tipoSimbolo]
    @init {$tipoSimbolo="";}
     : registro[$tipo_registro] {$tipoSimbolo="registro";}
     | tipo_estendido { $tipoSimbolo = $tipo_estendido.tipoSimbolo;}
     ;

mais_ident returns [String txt, int linha]
@init {$txt=""; $linha=-1;}
    : (VIRGULA v1=identificador {$txt=$v1.txt; $linha=$v1.linha;})*
           ;
	
mais_variaveis returns[ List<String> nomes, String tipoSimbolo, int linha ]
@init { $nomes = new ArrayList<String>(); $tipoSimbolo=""; $linha=-1; }
    : variavel f1=mais_variaveis { $nomes.addAll($variavel.nomes); $tipoSimbolo=$variavel.tipoSimbolo; $linha=$variavel.linha; $nomes.addAll($f1.nomes); } | ;
      

tipo_basico returns [String tipoSimbolo]
@init {$tipoSimbolo="";}
            : LITERAL {$tipoSimbolo = "literal";}
            | INTEIRO {$tipoSimbolo = "inteiro";}
            | REAL    {$tipoSimbolo = "real";}
            | LOGICO  {$tipoSimbolo = "logico";}
            ;

tipo_basico_ident returns [String tipoSimbolo]
    @init {$tipoSimbolo="";}
                  : v1=tipo_basico {$tipoSimbolo = $v1.tipoSimbolo;}
                  | v2=IDENT       {$tipoSimbolo = $v2.getText();}
                  ;

tipo_estendido returns [String tipoSimbolo]
    @init {$tipoSimbolo="";}
               : ponteiros_opcionais v1=tipo_basico_ident {$tipoSimbolo = $v1.tipoSimbolo;}
               ;

valor_constante : CADEIA
                | NUM_INT
                | NUM_REAL
                | VERDADEIRO
                | FALSO
                ;

registro [String nome_registro]
    : REGISTRO 
      {
       pilhaDeTabelas.empilhar(new TabelaDeSimbolos("registro"));
       TabelasDeRegistros.empilhar(new TabelaDeSimbolos($nome_registro));
       
      }
      
      variavel mais_variaveis
      
      {
       for (String s : $variavel.nomes){
                   TabelasDeRegistros.topo().adicionarSimbolo(s, $variavel.tipoSimbolo);
       }
    
        for (String u : $mais_variaveis.nomes){
                   //error+=u+"\n";
                   TabelasDeRegistros.topo().adicionarSimbolo(u, $mais_variaveis.tipoSimbolo);
        }
       
       
       }
      
      FIM_REGISTRO
      {
       pilhaDeTabelas.desempilhar();
      }
         ;

declaracao_global : PROCEDIMENTO v1=IDENT
                    {
                    if(pilhaDeTabelas.topo().existeSimbolo($v1.getText()))
                        error += "Linha " + $v1.getLine() + ": identificador "+$v1.getText()+" ja declarado anteriormente\n" ;
                    else{
                         pilhaDeTabelas.topo().adicionarSimbolo($v1.getText(), "procedimento");
                         pilhaDeTabelas.empilhar(new TabelaDeSimbolos("procedimento"));

                    }
                    }
                    
                    ABREPARENTESE parametros_opcional FECHAPARENTESE declaracoes_locais comandos FIM_PROCEDIMENTO 
                    {pilhaDeTabelas.desempilhar();}
                    
                  | FUNCAO v1=IDENT 
                    
                    {
                    if(pilhaDeTabelas.topo().existeSimbolo($v1.getText()))
                        error += "Linha " + $v1.getLine() + ": identificador "+$v1.getText()+" ja declarado anteriormente\n" ;
                    else{
                        pilhaDeTabelas.topo().adicionarSimbolo($v1.getText(), "funcao");
                        pilhaDeTabelas.empilhar(new TabelaDeSimbolos("funcao"));
                        
                    }
                    }
                    
                    ABREPARENTESE parametros_opcional FECHAPARENTESE DOISPONTOS tipo_estendido 
                    
                    declaracoes_locais comandos FIM_FUNCAO
                    {pilhaDeTabelas.desempilhar();}
                  ;

parametros_opcional : parametro
                    |
                    ;

parametro : var_opcional v1=identificador v3=mais_ident DOISPONTOS v2=tipo_estendido mais_parametros
            
             {
                    if(pilhaDeTabelas.topo().existeSimbolo($v1.txt))
                        error += "Linha " + $v1.linha + ": identificador "+$v1.txt+" ja declarado anteriormente\n" ;
                    else{
                        pilhaDeTabelas.topo().adicionarSimbolo($v1.txt, $v2.tipoSimbolo);
                       //error+=pilhaDeTabelas.topo().getEscopo();
                        if(TabelasDeRegistros.existeTabela($v2.tipoSimbolo)!=null)
                            {
                               TabelaDeSimbolos tabela_registro = TabelasDeRegistros.existeTabela($v2.tipoSimbolo);
                               for (String t : tabela_registro.getSimbolos())
                               {
                                pilhaDeTabelas.topo().adicionarSimbolo($v1.txt+t, $v2.tipoSimbolo);
                               }
                             }
                        
                    }                    
             }
            
            
            
            
            
          ;

var_opcional : VAR
             |
             ;

mais_parametros: VIRGULA parametro
               |
               ;

declaracoes_locais: decl_local*
                  ;

corpo : declaracoes_locais comandos
      ;

comandos : cmd*
         ;

cmd returns [ String tipoCmd ]
    : LEIA ABREPARENTESE v10=identificador {if(!pilhaDeTabelas.existeSimbolo($v10.txt))
               error+="Linha " + $v10.linha + ": identificador " + $v10.txt + " nao declarado\n";}  v11=mais_ident {
                                                                                                                    if(!$v11.txt.equals("")){
                                                                                                                       if(!pilhaDeTabelas.existeSimbolo($v11.txt))
                                                                                                                            error+="Linha " + $v11.linha + ": identificador " + $v11.txt + " nao declarado\n";
                                                                                                                    }
                                                                                                                  
                                                                                                                  
                                                                                                                   }
      FECHAPARENTESE { $tipoCmd = "leia"; }
    | ESCREVA ABREPARENTESE expressao mais_expressao FECHAPARENTESE { $tipoCmd = "escreva"; }
    | SE expressao ENTAO comandos senao_opcional FIM_SE { $tipoCmd = "se"; }
    | CASO exp_aritmetica SEJA selecao senao_opcional FIM_CASO
    | PARA v1=IDENT ATRIBUICAO exp_aritmetica ATE exp_aritmetica FACA comandos FIM_PARA
      /*{
           if(!pilhaDeTabelas.existeSimbolo($v1.getText()))
               error+="Linha " + $v1.getLine() + ": identificador " + $v1.getText() + " nao declarado";
      }*/
    | ENQUANTO expressao FACA comandos FIM_ENQUANTO
    | FACA comandos ATE expressao
    | EXPOENTE v2=IDENT outros_ident dimensao ATRIBUICAO expressao
      /*{
          if(!pilhaDeTabelas.existeSimbolo($v2.getText()))
                error+="Linha " + $v2.getLine() + ": identificador " + $v2.getText() + " nao declarado"; 
      }*/
    | v3=IDENT chamada_atribuicao[$v3.text]
      {
          if(!pilhaDeTabelas.existeSimbolo($v3.getText()))
              error+="Linha " + $v3.getLine() + ": identificador " + $v3.getText() + " nao declarado\n"; 

      }
    | v4=RETORNE expressao
      {
        String escopoAtual=pilhaDeTabelas.topo().getEscopo();
        if(escopoAtual.equals("funcao")==false){
            error+="Linha " + $v4.getLine() + ": comando retorne nao permitido nesse escopo\n";
        }
      }
    ;

mais_expressao : (VIRGULA expressao)*
               ;

senao_opcional : SENAO comandos
               |
               ;

chamada_atribuicao[String primeiroIdent]
    : ABREPARENTESE argumentos_opcional FECHAPARENTESE
                   | outros_ident dimensao ATRIBUICAO e1=expressao { String tipoExp = VerificadorDeTipos.verificaTipo($e1.ctx); }
                   ;

argumentos_opcional : expressao mais_expressao
                    |
                    ;

selecao : constantes DOISPONTOS comandos mais_selecao
        ;

mais_selecao : selecao
             |
             ;

constantes : numero_intervalo mais_constantes
           ;

mais_constantes : VIRGULA constantes
                |
                ;

numero_intervalo : op_unario NUM_INT intervalo_opcional
                 ;

intervalo_opcional : PONTOPONTO op_unario NUM_INT
                   |
                   ;

op_unario : SUBTRACAO
          |
          ;

exp_aritmetica : termo outros_termos
               ;

op_multiplicacao : MULTIPLICACAO
                 | DIVISAO
                 ;

op_adicao : SOMA
          | SUBTRACAO
          ;

termo :	fator outros_fatores
      ;

outros_termos : (op_adicao termo)*
              ;

fator : parcela outras_parcelas
      ;

outros_fatores : (op_multiplicacao fator)*
               ;

parcela : op_unario parcela_unario
        | parcela_nao_unario
        ;

parcela_unario returns [String txt, int linha] 
     @init {$txt=""; $linha=-1;}
    : EXPOENTE v1=IDENT {$txt+=$v1.getText(); $linha = $v1.getLine(); } oi=outros_ident dimensao
      
      { if(!pilhaDeTabelas.existeSimbolo($v1.getText()+$oi.txt))
               error+="Linha " + $v1.getLine() + ": identificador " + $v1.getText()+$oi.txt + " nao declarado\n";
      }
                
               | v2=IDENT {
                           $txt+=$v2.getText(); $linha = $v2.getLine();
                           if(!pilhaDeTabelas.existeSimbolo($v2.getText()))
                              error+="Linha " + $v2.getLine() + ": identificador " + $v2.getText() + " nao declarado\n";
                           
                           } chamada_partes
                 
               | NUM_INT
               | NUM_REAL
               | ABREPARENTESE expressao FECHAPARENTESE
               ;

parcela_nao_unario returns [String txt, int linha]
@init {$txt=""; $linha=-1;}
    : OPERADOR_E v1=IDENT {$txt+=$v1.getText(); $linha = $v1.getLine();} v2=outros_ident dimensao
    
                   | CADEIA
                   ;

outras_parcelas : (PORCENTAGEM parcela)*
                ;

chamada_partes : ABREPARENTESE expressao mais_expressao FECHAPARENTESE
               | outros_ident dimensao
               |
               ;

exp_relacional : exp_aritmetica op_opcional
               ;

op_opcional : op_relacional exp_aritmetica
            |
            ;

op_relacional : IGUAL
              | DIFERENTE
              |	MAIORIGUAL
              |	MENORIGUAL
              |	MAIOR
              |	MENOR
              ;

expressao : termo_logico outros_termos_logicos
          ;

op_nao : NAO
       |
       ;

termo_logico : fator_logico outros_fatores_logicos
             ;

outros_termos_logicos : (OU termo_logico)*
                      ;

outros_fatores_logicos : (E fator_logico)*
                       ;

fator_logico: op_nao parcela_logica
            ;

parcela_logica: VERDADEIRO
              | FALSO
              | exp_relacional
              ;