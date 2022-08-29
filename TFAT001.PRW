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
Descricao 	|	Esse PE é responsável por fazer a integração dos clientes alterados e incluidos via
            |   Protheus na aplicação Web utilizada. 
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

        If(cIDPonto == "FORMPOS")// PE da Validação do Formulário.
            cNome       := AllTrim(M->A1_NOME)
            cNomeReduz  := AllTrim(M->A1_NREDUZ)
            cDoc        := AllTrim(M->A1_CGC)
            cEmail      := AllTrim(M->A1_EMAIL)
            cPessoa     := AllTrim(M->A1_TIPO)
            cTelefone   := AllTrim(M->A1_TEL)
            cDDD        := AllTrim(M->A1_DDD)

            // Validação dos campos obrigatórios da integração
            If(Empty(cNome))
                APMsgAlert('Campo [ NOME COMPLETO ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf
            If(Empty(cNomeReduz))
                APMsgAlert('Campo [ NOME FANTASIA ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf
            If(Empty(cDoc))
                APMsgAlert('Campo [ CNPJ/CPF ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf
            If(Empty(cEmail))
                APMsgAlert('Campo [ EMAIL ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf
            If(Empty(cPessoa))
                APMsgAlert('Campo [ FISICA/JURID ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf
            If(Empty(cTelefone))
                APMsgAlert('Campo [ TELEFONE ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf
            If(Empty(cDDD))
                APMsgAlert('Campo [ DDD ] não está preenchido!','Erro na Integração')
                xRet := .F.
            EndIf

            If xRet // Se todos os campos válidos
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
Função		: sfIntegracao
Data		: 29/08/2022
Autor       : Eduardo Garcia
Descrição	: Função responsável por fazer a requisição PUT ao WebService http://iws.grupoa.com.br
Parâmetros	: oJson de Envio e cCodCli com A1_COD
Retorno		: True or False
------------------------------------------------------------------------------------------------------------
*/
Static Function sfIntegracao(oJson,cCodCli)
    Local cUrl          := 'http://iws.grupoa.com.br' // URL Envio da Requisição
    Local cPath         := '/api/users/update/' // Path da Requisição + Código do Usuário
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
    
    // Como não tenho o retorno da API, presumi a palavra Sucesso como possível retorna na inclusão/alteração do cliente.
    // Mock de exemplo de possivel retorno da API: { "status": "Sucesso" } || { "status": "Email invalido" }
    If(cRespJSON $ "Sucesso")
        xRet := .T.
    ElseIf(cRespJSON $ "Erro")
        APMsgAlert('JSON de Erro: ' + cEOL + cRespJSON,'Erro na Integração')
    EndIf

    FreeObj(oRest)

Return (xRet)
