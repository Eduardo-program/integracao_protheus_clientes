#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH" 
#INCLUDE "JSON.CH"
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'PARMTYPE.CH'

/*/
-----------------------------------------------------------------------------------------------------
Funcao		|	CRMA980
Data		|	29/08/2022
Autor    	|	EduardoGarcia
-----------------------------------------------------------------------------------------------------
Parametros	|	Nenhum
-----------------------------------------------------------------------------------------------------
Retorno		|  	True or False
-----------------------------------------------------------------------------------------------------
Descricao 	|	Esse PE ? respons?vel por fazer a integra??o dos clientes alterados e incluidos via
            |   Protheus na aplica??o Web utilizada. 
-----------------------------------------------------------------------------------------------------
Uso		 	|   Ponto na Entrada, Cadastro de Cliente
-----------------------------------------------------------------------------------------------------
/*/ 
User Function CRMA980() //Ponto de Entrada do Cadastro de Clientes
    Local aParam        := PARAMIXB
    Local xRet          := .T.
    Local cIDPonto      := ''
    Local cIDModel      := ''
    Local oObj          := NIL
    Local cNome         := ''
    Local cNomeReduz    := ''
    Local cDoc          := ''
    Local cEmail        := ''
    Local cPessoa       := ''
    Local cTelefone     := ''
    Local cDDD          := ''
    Local cCodCli       := ''
    Local oJson      	:= NIL

    If aParam <> NIL

        oObj        := aParam[1]
        cIDPonto    := aParam[2]
        cIDModel    := aParam[3]

        If(cIDPonto == "FORMPOS")// PE da Valida??o do Formul?rio.
            cNome       := AllTrim(M->A1_NOME)
            cNomeReduz  := AllTrim(M->A1_NREDUZ)
            cDoc        := AllTrim(M->A1_CGC)
            cEmail      := AllTrim(M->A1_EMAIL)
            cPessoa     := AllTrim(M->A1_TIPO)
            cTelefone   := AllTrim(M->A1_TEL)
            cDDD        := AllTrim(M->A1_DDD)

            // Valida??o dos campos obrigat?rios da integra??o
            If(Empty(cNome))
                APMsgAlert('Campo [ NOME COMPLETO ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf
            If(Empty(cNomeReduz))
                APMsgAlert('Campo [ NOME FANTASIA ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf
            If(Empty(cDoc))
                APMsgAlert('Campo [ CNPJ/CPF ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf
            If(Empty(cEmail))
                APMsgAlert('Campo [ EMAIL ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf
            If(Empty(cPessoa))
                APMsgAlert('Campo [ FISICA/JURID ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf
            If(Empty(cTelefone))
                APMsgAlert('Campo [ TELEFONE ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf
            If(Empty(cDDD))
                APMsgAlert('Campo [ DDD ] n?o est? preenchido!','Erro na Integra??o')
                xRet := .F.
            EndIf

            If xRet // Se todos os campos v?lidos
                oJson 	    := JsonObject():New()
                cCodCli     := AllTrim(M->A1_COD)

                // Montagem do Json de Envio
                oJson["nome"]           := AllTrim(M->A1_NOME)
                oJson["nomereduz"]      := AllTrim(M->A1_NREDUZ)
                oJson["documento"]      := AllTrim(M->A1_CGC)
                oJson["email"]          := AllTrim(M->A1_EMAIL)
                oJson["tipoPessoa"]     := AllTrim(M->A1_TIPO)
                oJson["telefone"]       := AllTrim(M->A1_TEL)
                oJson["ddd"]            := AllTrim(M->A1_DDD)

                xRet := sfIntegracao(oJson, cCodCli)
            EndIf

        EndIf

    EndIf

Return (xRet)

/*
------------------------------------------------------------------------------------------------------------
Fun??o		: sfIntegracao
Data		: 29/08/2022
Autor       : Eduardo Garcia
Descri??o	: Fun??o respons?vel por fazer a requisi??o PUT ao WebService http://iws.grupoa.com.br
Par?metros	: oJson de Envio e cCodCli com A1_COD
Retorno		: True or False
------------------------------------------------------------------------------------------------------------
*/
Static Function sfIntegracao(oJson,cCodCli)
    Local cUrl          := 'http://iws.grupoa.com.br' // URL Envio da Requisi??o
    Local cPath         := '/api/users/update/' // Path da Requisi??o + C?digo do Usu?rio
    Local aHeadStr      := {}
    Local xRet          := .F.
	Local oRest         := Nil
    Local cRespJSON     := ''
    Local cEOL          := CHR(13) + CHR(10)

	aadd(aHeadStr,"Content-Type: application/json")
	aadd(aHeadStr,"Authorization: Basic cHJvdGhldXMtaU50ZWdyYXRpb246WWQ0bHZAUk14Z25AcEgwcEMPXk9lITk0")

    oRest 	:= FWRest():New(cUrl)
    oRest:SetPath(cPath + cCodCli)
    oRest:Put(aHeadStr, oJson:ToJson())
    cRespJSON := oRest:GetResult()
    // cRespJSON := "Erro"
    // cRespJSON := "Sucesso"
    
    // Como n?o tenho o retorno da API, presumi a palavra Sucesso como poss?vel retorna na inclus?o/altera??o do cliente.
    // Mock de exemplo de possivel retorno da API: { "status": "Sucesso" } || { "status": "Email invalido" }
    If(cRespJSON $ "Sucesso")
        xRet := .T.
    ElseIf(cRespJSON $ "Erro")
        APMsgAlert('JSON de Erro: ' + cEOL + cRespJSON,'Erro na Integra??o')
    EndIf

    FreeObj(oRest)

Return (xRet)
