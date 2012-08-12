//======================================================================
//    TsubuyakiSoup
//----------------------------------------------------------------------
//    HSP����Twitter�𑀍삷�郂�W���[���B
//    OAuth/xAuth�ɑΉ����Ă��邽�߁ABASIC�F�؂��p�~���ꂽ�����ł�
//  TwitterAPI�𗘗p���邱�Ƃ��ł��܂��B
//----------------------------------------------------------------------
//  Version : 1.5
//  Author : Takaya
//  CreateDate : 10/07/29
//  LastUpdate : 11/09/14
//======================================================================
/*  [HDL module infomation]

%dll
TsubuyakiSoup

%ver
1.1

%date
2010/11/14

%note
TsubuyakiSoup.as���C���N���[�h���邱�ƁB

%port
Win

%*/

#include "encode.as"
#undef                  sjis2utf8n(%1, %2)
#define global          sjis2utf8n(%1, %2) _FromSJIS@mod_encode %2, CODEPAGE_S_JIS, %1, CODEPAGE_UTF_8
#undef                  utf8n2sjis(%1)
#define global ctype    utf8n2sjis(%1)     _ToSJIS@mod_encode(%1, CODEPAGE_UTF_8,  CODEPAGE_S_JIS)



//  ------------------------------------------------------------
//    ���W���[���J�n
#module TsubuyakiSoup

//------------------------------
//  WinAPI
//------------------------------
//---------------
//  advapi32.dll
//---------------
#uselib "advapi32.dll"
#cfunc _CryptAcquireContext "CryptAcquireContextA" var, sptr, sptr, int, int
#cfunc _CryptCreateHash "CryptCreateHash" sptr, int, int, int, var
#cfunc _CryptHashData "CryptHashData" sptr, sptr, int, int
#cfunc _CryptSetHashParam "CryptSetHashParam" sptr, int, var, int
#cfunc _CryptGetHashParam "CryptGetHashParam" sptr, int, sptr, var, int
#cfunc _CryptImportKey "CryptImportKey" sptr, var, int, int, int, var
#func _CryptDestroyKey "CryptDestroyKey" int
#func _CryptDestroyHash "CryptDestroyHash" int
#func _CryptReleaseContext "CryptReleaseContext" int, int
#cfunc _CryptDeriveKey "CryptDeriveKey" int, int, int, int, var
#cfunc _CryptEncrypt "CryptEncrypt" int, int, int, int, int, var, int
#cfunc _CryptDecrypt "CryptDecrypt" int, int, int, int, var, var
//---------------
//  wininet.dll
//---------------
#uselib "wininet.dll"
#cfunc _InternetOpen "InternetOpenA" sptr, int, sptr, sptr, int
#cfunc _InternetOpenUrl "InternetOpenUrlA" int, str, sptr, int, int, int
#func _InternetReadFile "InternetReadFile" int, var, int, var
#func _InternetCloseHandle "InternetCloseHandle" int
#cfunc _InternetConnect "InternetConnectA" int, str, int, sptr, sptr, int, int, int
#cfunc _HttpOpenRequest "HttpOpenRequestA" int, sptr, str, sptr, sptr, sptr, int, int
#cfunc _HttpSendRequest "HttpSendRequestA" int, sptr, int, sptr, int
#cfunc _HttpQueryInfo "HttpQueryInfoA" int, int, var, var, int
#func _InternetQueryDataAvailable "InternetQueryDataAvailable" int, var, int, int
#func _InternetSetOption "InternetSetOptionA" int, int, int, int
//---------------
//  crtdll.dll
//---------------
#uselib "crtdll.dll"
#func _time "time" var




//------------------------------
//  �萔
//------------------------------
//HTTP���\�b�h
#define global METHOD_GET	0
#define global METHOD_POST	1




//============================================================
/*  [HDL symbol infomation]

%index
Encryption
��������Í���

%prm
(p1, p2)
p1 = �ϐ�      : �Í������镶������������ϐ�
p2 = ������    : ���Ƃ��镶����

%inst
�������RC4�A���S���Y���ňÍ������܂��B��������� 1 �A���s����� 0 ���Ԃ�܂��B

�Í������镶������������ϐ���p1�Ɏw�肵�܂��B�Í������ꂽ�������p1�̕ϐ��ɕԂ�܂��B

�Í������邽�߂̌��i�L�[�j�́Ap2�ŕ�����Ƃ��Ďw�肵�܂��B

�֐����s���ɁAp1�̕ϐ��̓��e�������������Ă��܂����ƂɋC�����Ă��������B

���̊֐��ňÍ������ꂽ������́ADecryption�֐��ŕ����ɕ������邱�Ƃ��ł��܂��B

%group
TsubuyakiSoup�⏕�֐�

%href
Decryption

%*/
//------------------------------------------------------------
#defcfunc Encryption var p1, str p2
	EncryptStrLen = strlen(p1)
	EncryptStrLen2 = strlen(p1)
	refstat = 0
	if ( _CryptAcquireContext(hProv, 0, 0, 1, 0) = 0) {
		 if ( _CryptAcquireContext(hProv, 0, "Microsoft Enhanced Cryptographic Provider v1.0", 1, 0x00000008) = 0) {
		 	return 0
		 }
	}
	//�n�b�V���쐬
	if ( _CryptCreateHash(hProv, 0x00008004, 0, 0, hHash) ) {
		//�n�b�V���l�v�Z
		if ( _CryptHashData(hHash, p2, strlen(p2), 0) ) {
			//�Í����̐���
			if ( _CryptDeriveKey(hProv, 0x00006801, hHash, 0x800000, hKey) ) {
				//�Í���
				if ( _CryptEncrypt( hKey, 0, 1, 0, 0, EncryptStrLen, 0) ) {		;�o�b�t�@�̊m�ۗp
					memexpand p1, EncryptStrLen+1
					if ( _CryptEncrypt( hKey, 0, 1, 0, varptr(p1), EncryptStrLen2, EncryptStrLen) ) {	;�Í���
						refstat = 1
					}
				}
				_CryptDestroyKey hKey
			}
		}
		_CryptDestroyHash hHash
	}
	_CryptReleaseContext hProv, 0
return refstat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
Decryption
������𕜍�

%prm
(p1, p2)
p1 = �ϐ�      : �������镶������������ϐ�
p2 = ������    : ���Ƃ��镶����

%inst
RC4�A���S���Y���ňÍ������ꂽ������𕜍����܂��B��������� 1 �A���s����� 0 ���Ԃ�܂��B

�������镶����ϐ���p1�Ɏw�肵�܂��B�������ꂽ�������p1�̕ϐ��ɕԂ�܂��B

�������邽�߂̌��i�L�[�j�́Ap2�ŕ�����Ƃ��Ďw�肵�܂��B

�֐����s���ɁAp1�̕ϐ��̓��e�������������Ă��܂����ƂɋC�����Ă��������B

%group
TsubuyakiSoup�⏕�֐�

%href
Encryption

%*/
//------------------------------------------------------------
#defcfunc Decryption var p1, str p2
	EncryptStrLen = strlen(p1)
	refstat = 0
	if ( _CryptAcquireContext(hProv, 0, 0, 1, 0) = 0) {
		 if ( _CryptAcquireContext(hProv, 0, "Microsoft Enhanced Cryptographic Provider v1.0", 1, 0x00000008) = 0) {
		 	return 0
		}
	}
	//�n�b�V���쐬
	if ( _CryptCreateHash(hProv, 0x00008004, 0, 0, hHash) ) {
		//�n�b�V���l�v�Z
		if ( _CryptHashData(hHash, p2, strlen(p2), 0) ) {
			//�Í����̐���
			if ( _CryptDeriveKey(hProv, 0x00006801, hHash, 0x800000, hKey) ) {
				//����
				if ( _CryptDecrypt( hKey, 0, 1, 0, p1, EncryptStrLen) ) {
					refstat = 1
				}
				_CryptDestroyKey hKey
			}
		}
		_CryptDestroyHash hHash
	}
	_CryptReleaseContext hProv, 0
return refstat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
HMAC_SHA1
HMAC-SHA1�ŏ����𐶐�

%prm
(p1, p2)
p1 = ������    : ���������镶����
p2 = ������    : ���Ƃ��镶����

%inst
SHA-1�n�b�V���֐����g�p�����n�b�V�����b�Z�[�W�F�؃R�[�h�iHMAC�j��Ԃ��܂��B

p1�ɏ��������镶������w�肵�܂��B

���������邽�߂̌��i�L�[�j�́Ap2�ŕ�����Ŏw�肵�܂��B

%href
SignatureEncode

%group
TsubuyakiSoup�⏕�֐�

%*/
//------------------------------------------------------------
#defcfunc HMAC_SHA1 str p1, str p2
	HS_p1 = p1
	HS_p2 = p2
	HS_SigLen = 0
	HS_dest = ""
	//�n�b�V��
	HS_hProv = 0
	HS_hKey = 0
	HS_hHash = 0
	sdim HS_HmacInfo,14
	lpoke HS_HmacInfo, 0, 0x00008004
	;key�̐���
	dim HS_keyBlob,350
	poke HS_keyBlob,0,0x8					;bType
	poke HS_keyBlob,1,2						;bVersion
	lpoke HS_keyBlob,2,0					;reserved
	HS_keyBlob(1) = 0x00006602				;aiKeyAlg
	HS_keyBlob(2) = strlen(HS_p2)	;len
	memcpy HS_keyBlob, HS_p2, HS_keyBlob(2), 12, 0
	//�R���e�L�X�g�̎擾
	if ( _CryptAcquireContext(HS_hProv, 0, 0, 1, 0) ) {
		//�L�[�̃C���|�[�g
		if ( _CryptImportKey(HS_hProv, HS_keyBlob, (12+HS_keyBlob(2)), 0, 0x00000100, HS_hKey) ) {
			//�n�b�V��������
			if ( _CryptCreateHash(HS_hProv, 0x00008009, HS_hKey, 0, HS_hHash) ) {
				//�n�b�V���p�����[�^�̐ݒ�
				if ( _CryptSetHashParam(HS_hHash, 0x0005, HS_HmacInfo, 0) ) {
					//�n�b�V���ɏ�������
					if ( _CryptHashData(HS_hHash, HS_p1, strlen(HS_p1), 0) ) {
						//�n�b�V���擾
						if ( _CryptGetHashParam(HS_hHash, 0x0002, 0, HS_size, 0) ) {
							sdim HS_dest, HS_size
							if ( _CryptGetHashParam(HS_hHash, 0x0002, varptr(HS_dest), HS_size, 0) ) {
							}
						}
					}
				}
				//�n�b�V���n���h���̔j��
				_CryptDestroyHash HS_hHash
			}
			//�L�[�n���h���̔j��
			_CryptDestroyKey HS_hKey
		}
		//�n���h���̔j��
		_CryptReleaseContext HS_hProv, 0
	}
return HS_dest
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
SignatureEncode
OAuth/xAuth�p�V�O�l�`���𐶐�

%prm
(p1, p2)
p1 = ������    : ���������镶����
p2 = ������    : ���Ƃ��镶����

%inst
OAuth/xAuth�p�̏�����Ԃ��܂��B

p1�ɏ��������镶������w�肵�܂��B

���������邽�߂̌��i�L�[�j�́Ap2�ŕ�����Ŏw�肵�܂��B

Twitter�̃V�O�l�`�������̎d�l���A
�����R�[�hUTF-8��URL�G���R�[�h����������ip1�j���A������URL�G���R�[�h����������ip2�j���L�[�Ƃ���HAMAC-SHA1�����Ő��������������ABASE64�G���R�[�h��������URL�G���R�[�h���Ă��܂��B

%href
HMAC_SHA1

%group
TsubuyakiSoup�⏕�֐�

%*/
//------------------------------------------------------------
#defcfunc SignatureEncode str p1, str p2
	//utf-8�֕ϊ�
	sjis2utf8n SigTmp, p1
	sjis2utf8n SecretTmp, p2
	//URL�G���R�[�h�B
	SigEnc = form_encode( SigTmp, 0)
	SecretEnc = form_encode( SecretTmp, 0)
	//HMAC-SHA1
	SigTmp = HMAC_SHA1( SigEnc, SecretEnc)
	//BASE64
	SigEnc = base64encode(SigTmp)
	//URL�G���R�[�h
	SigTmp = form_encode( SigEnc, 0)
return SigTmp
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
RESTAPI
TwitterAPI�����s

%prm
p1, p2, p3, p4, p5
p1 = �ϐ�      : �������ʂ�������ϐ�
p2 = �ϐ�      : ���X�|���X�w�b�_��������ϐ�
p3 = 0�`1(0)   : ���\�b�h GET(0) POST(1)
p4 = ������    : API
p5 = �z��      : API�ɓY�����������������������z��

%inst
TwitterAPI�����s���ATwitter����Ԃ��Ă����X�e�[�^�X�R�[�h��߂�l�Ƃ���stat�ɕԂ��܂��B

p1,p2�ɂ͂��ꂼ�ꉞ�����ʂƃw�b�_�������镶����^�ϐ����w�肵�܂��B

p3�Ń��\�b�h���w�肷�邱�Ƃ��ł��܂��B"GET"�ő��M����ꍇ�� 0 ���A"POST"�ő��M����ꍇ�� 1 ���w�肵�Ă��������B���̑��̒l���w�肵���ꍇ�́A�����I��"GET"���\�b�h���g�p���܂��B
TwitterAPI�Ŏw�肳��Ă��郁�\�b�h��I�����Ă��������B

p4�Ŏ��s����TwitterAPI���擾�������t�H�[�}�b�g�ƂƂ��Ɏw�肵�܂��B
    �� : "statuses/mentions.xml"      �����ւ̌��y��XML�`���Ŏ擾
         "statuses/update.json"       Twitter�֓��e���A���ʂ�JSON�`���Ŏ擾
�Ȃ��ATwitterAPI���ƂɎw��ł���t�H�[�}�b�g�����܂��Ă���̂ŋC�����Ă��������B


TwitterAPI�ɓn�������𕶎���^�̔z��ɂ���p5�Ɏw�肵�܂��B
�Ⴆ�΁AAPI"home_timeline"�Ɉ���"trim_user=true"��"count=50"���w�肵�āA�z�[���^�C�����C�������[�U�������[�UID�����ɂ���50���擾����Ƃ��܂��B
    Argument(0) = "trim_user=true"
    Argument(1) = "count=50"
    RESTAPI ResponseBody, ResponseHeader, 0, "statuses/home_timeline.xml", Argument


�V�O�l�`���̕t���Ȃǂ͖��ߑ��ł��Ă��܂��̂ŁATwitterAPI�̃��t�@�����X�ɋL�ڂ���Ă�������ȊO�͎w�肷��K�v�͂���܂���B
�܂��A"oauth/request_token"��"oauth/access_token"���Ăяo���ہA������
"oauth_consumer_key","oauth_nonce","oauth_signature_method","oauth_timestamp","oauth_token","oauth_version","oauth_signature"�ɂ��Ă͖��ߑ��ŏ����E�t�����Ă��܂��̂ŁA�w�肵�Ȃ��ł��������B
��Ƃ��āA�F�ؕ�����xAuth���g��"oauth/access_token"�ŃA�N�Z�X�g�[�N�����擾���鏈��
    Argument(0) = "x_auth_mode=client_auth"
    Argument(1) = "x_auth_password=xxxxxx"
    Argument(2) = "x_auth_username=xxxxxxxx"
    RESTAPI ResponseBody, ResponseHeader, 1, "oauth/access_token", Argument
^

%group
TwitterAPI���얽��

%url
http://watcher.moe-nifty.com/memo/docs/twitterAPI.txt

%*/
//------------------------------------------------------------
#deffunc RESTAPI var p1, var p2, int p3, str p4, array p5
//  �����`�F�b�N��������
	sdim p1
	sdim p2
	API = p4
	if vartype(p5) != 2 : return 0
	hConnect = 0		//InternetConnect�̃n���h��
	hRequest = 0		//HttpOpenRequest�̃n���h��
	API_statcode = 0	//���N�G�X�g�̌��ʃR�[�h
	API_p1Length = 0	//�f�[�^��
	API_rsize = 1024	//�o�b�t�@�����l
	API_hsize = 0		//�擾�����o�C�g������������ϐ�
//  ���\�b�h�̐ݒ�
	if (p3 = 1) {
		Method = "POST"
	} else {
		Method = "GET"
	}
//  �|�[�g���t���O�̐ݒ�
	UsePort = 443 : RequestFlag = -2139082752
	VersionStr = "1/"
	TokenStr = TS_AccessToken
	SigKey = TS_Consumer_Secret+" "+TS_AccessTokenSecret
	if (strmid(API,0,5) = "oauth") {
		VersionStr = ""
		if (API = "oauth/access_token") {
			//OAuth�F�؂�������A
			repeat length(p5)
				if (p5(cnt) = "x_auth_mode=client_auth") : break
				if cnt = length(p5)-1 : TokenStr = TS_RequestToken : SigKey = TS_Consumer_Secret+" "+TS_RequestTokenSecret
			loop
		}
	}
//  �V�O�l�`������
	SigArrayMax = 6 + length(p5)
	sdim SigArray, 500, SigArrayMax
	SigNonce = RandomString(8,32)
	_time SigTime
	SigArray(0) = "oauth_consumer_key=" + TS_Consumer_Key
	SigArray(1) = "oauth_nonce=" + SigNonce
	SigArray(2) = "oauth_signature_method=HMAC-SHA1"
	SigArray(3) = "oauth_timestamp=" + SigTime
	SigArray(4) = "oauth_token="+ TokenStr
	SigArray(5) = "oauth_version=1.0"
	repeat SigArrayMax - 6
		SigArray(6+cnt) = p5(cnt)
	loop
	//�\�[�g
	SortString SigArray
	//"&"�ŘA��
	TransStr = ""+ Method +" https://api.twitter.com/"+ VersionStr + API +" "
	repeat SigArrayMax
		if SigArray(cnt) = "" : continue
		TransStr += SigArray(cnt) +"&"
	loop
	TransStr = strmid(TransStr, 0, strlen(TransStr)-1)
	Signature = SignatureEncode(TransStr, SigKey)
//  �f�[�^���`
	if (p3 = 1) {
		//POST
		PostStr = ""
		repeat SigArrayMax
			PostStr += SigArray(cnt) +"&"
		loop
		PostStr += "oauth_signature="+ Signature
		PostStrLen = strlen(PostStr)
		AddUrl = ""
	} else {
		//GET
		PostStr = 0
		PostStrLen = 0
		AddUrl = "?"
		repeat SigArrayMax
			AddUrl += SigArray(cnt) +"&"
		loop
		AddUrl += "oauth_signature="+ Signature
	}
	//�T�[�o�֐ڑ�
	hConnect = _InternetConnect(TS_hInet, "api.twitter.com", UsePort, 0, 0, 3, 0, 0)
	if (hConnect) {
		//���N�G�X�g�̏�����
		hRequest = _HttpOpenRequest(hConnect, Method, VersionStr+API+AddUrl, "HTTP/1.1", 0, 0, RequestFlag, 0)
		if (hRequest) {
			//�T�[�o�փ��N�G�X�g���M
			if ( _HttpSendRequest(hRequest, "Accept-Encoding: gzip, deflate", -1, PostStr, PostStrLen)) {
				//�w�b�_���擾����ϐ��̏�����
				p2Size = 3000
				sdim p2, p2Size
				//�w�b�_�̎擾
				if ( _HttpQueryInfo(hRequest, 22, p2, p2Size, 0) ) {
					//�w�b�_�̉��
					notesel p2
					repeat notemax
						noteget API_BufStr, cnt
						API_buf = instr(API_BufStr, 0, "Status: ")				//�X�e�[�^�X�R�[�h
						if (API_Buf != -1) : API_statcode = int(strmid(API_BufStr, API_buf+8, 3))
						API_buf = instr(API_BufStr, 0, "Content-Length: ")		//����
						if (API_Buf != -1) : API_p1Length = int(strmid(API_BufStr, -1, strlen(API_BufStr)-API_buf+16))
						API_buf = instr(API_BufStr, 0, "X-RateLimit-Limit: ")		//60���Ԃ�API�����s�ł����
						if (API_Buf != -1) : TS_RateLimit(0) = int(strmid(API_BufStr, -1, strlen(API_BufStr)-(API_buf+19)))
						API_buf = instr(API_BufStr, 0, "X-RateLimit-Remaining: ")	//API�����s�ł���c���
						if (API_Buf != -1) : TS_RateLimit(1) = int(strmid(API_BufStr, -1, strlen(API_BufStr)-(API_buf+23)))
						API_buf = instr(API_BufStr, 0, "X-RateLimit-Reset: ")		//���Z�b�g���鎞��
						if (API_Buf != -1) : TS_RateLimit(2) = int(strmid(API_BufStr, -1, strlen(API_BufStr)-(API_buf+19)))
					loop
					noteunsel
					//����\�ȃf�[�^�ʂ��擾
					_InternetQueryDataAvailable hRequest, API_rsize, 0, 0
					//�o�b�t�@�̏�����
					sdim API_bufStr, API_rsize+1
					sdim p1, API_p1Length+1
					repeat 
						_InternetReadFile hRequest, API_bufStr, API_rsize, API_hsize
						if (API_hsize = 0) : break 
						p1 += strmid(API_bufStr, 0, API_hsize)
						await 0
					loop
				} else {
					//�w�b�_�̎擾���ł��Ȃ������ꍇ
					API_statcode = -1
				}
			} else {
				//�T�[�o�փ��N�G�X�g���M�ł��Ȃ������ꍇ
				API_statcode = -2
			}
			//Request�n���h���̔j��
			_InternetCloseHandle hRequest
		} else {
			//Request�n���h�����擾�ł��Ȃ������ꍇ
			API_statcode = -3
		}
		//Connect�n���h���̔j��
		_InternetCloseHandle hConnect
	} else {
		//Connect�n���h�����擾�ł��Ȃ������ꍇ
		API_statcode = -4
	}
return API_statcode
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
SearchAPI
�X�e�[�^�X������

%prm
p1, p2, p3, p4, p5
p1 = �ϐ�      : �������ʂ�������ϐ�
p2 = �ϐ�      : ���X�|���X�w�b�_��������ϐ�
p3 = ������    : API
p5 = �z��      : API�ɓY�����������������������z��

%inst
SearchAPI�����s���ATwitter����Ԃ��Ă����X�e�[�^�X�R�[�h��߂�l�Ƃ���stat�ɕԂ��܂��B

p1,p2�ɂ͂��ꂼ�ꉞ�����ʂƃw�b�_�������镶����^�ϐ����w�肵�܂��B

p3�Ŏ��s����SearchAPI���擾�������t�H�[�}�b�g�ƂƂ��Ɏw�肵�܂��B
    �� : "search.atom"      �������ʂ�ATOM�`���Ŏ擾
         "trends.json"      ���܁ATwitter �Ńz�b�g�Șb���JSON�`���Ŏ擾
�Ȃ��ASearchAPI���ƂɎw��ł���t�H�[�}�b�g�����܂��Ă���̂ŋC�����Ă��������B

TwitterAPI�ɓn�������𕶎���^�̔z��ɂ���p4�Ɏw�肵�܂��B
�Ⴆ�΁AAPI"search"�Ɉ���"q=hsp"��"rpp=50"���w�肵�āA"hsp"���܂܂ꂽ�X�e�[�^�X���������A50���擾����Ƃ��܂��B
    Argument(0) = "q=hsp"
    Argument(1) = "rpp=50"
    SearchAPI ResponseBody, ResponseHeader, "search.atom", Argument

TS_Init�Ń��[�U�G�[�W�F���g���w�肵�Ă��Ȃ��ꍇ�A������API�������󂯂邱�Ƃ�����܂��B

%href
TS_Init

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc SearchAPI var p1, var p2, str p3, array p4
	sdim p1
	sdim p2
	if vartype(p4) != 2 : return 0
	hConnect = 0		//InternetConnect�̃n���h��
	hRequest = 0		//HttpOpenRequest�̃n���h��
	API_statcode = 0	//���N�G�X�g�̌��ʃR�[�h
	API_p1Length = 0	//�f�[�^��
	API_rsize = 1024	//�o�b�t�@�����l
	API_hsize = 0		//�擾�����o�C�g������������ϐ�
	// 
	AddUrl = ""
	repeat length(p4)
		if length(p4) = cnt + 1 : AddUrl += p4(cnt) : break
		AddUrl += ""+ p4(cnt) +"&"
	loop
	hConnect = _InternetConnect(TS_hInet, "search.twitter.com", 80, 0, 0, 3, 0, 0)
	if (hConnect) {
		//���N�G�X�g�̏�����
		hRequest = _HttpOpenRequest(hConnect, "GET", p3 +"?"+ AddUrl, "HTTP/1.1", 0, 0, -2147483648, 0)
		if (hRequest) {
			//�T�[�o�փ��N�G�X�g���M
			if ( _HttpSendRequest(hRequest, 0, 0, 0, 0)) {
				//�w�b�_���擾����ϐ��̏�����
				p2Size = 3000
				sdim p2, p2Size
				//�w�b�_�̎擾
				if ( _HttpQueryInfo(hRequest, 22, p2, p2Size, 0) ) {
					notesel p2
					repeat notemax
						noteget API_BufStr, cnt
						API_buf = instr(API_BufStr, 0, "Status: ")				//�X�e�[�^�X�R�[�h
						if (API_Buf != -1) : API_statcode = int(strmid(API_BufStr, API_buf+8, 3))
						API_buf = instr(API_BufStr, 0, "Content-Length: ")		//����
						if (API_Buf != -1) : API_p1Length = int(strmid(API_BufStr, -1, strlen(API_BufStr)-API_buf+16))
					loop
					noteunsel
					//����\�ȃf�[�^�ʂ��擾
					_InternetQueryDataAvailable hRequest, API_rsize, 0, 0
					//�o�b�t�@�̏�����
					sdim API_bufStr, API_rsize+1
					sdim p1, API_p1Length+1
					repeat 
						_InternetReadFile hRequest, API_bufStr, API_rsize, API_hsize
						if (API_hsize = 0) : break 
						p1 += strmid(API_bufStr, 0, API_hsize)
						await 0
					loop
				} else {
					//�w�b�_�̎擾���ł��Ȃ������ꍇ
					API_statcode = -1
				}
			} else {
				//�T�[�o�փ��N�G�X�g���M�ł��Ȃ������ꍇ
				API_statcode = -2
			}
			//Request�n���h���̔j��
			_InternetCloseHandle hRequest
		} else {
			//Request�n���h�����擾�ł��Ȃ������ꍇ
			API_statcode = -3
		}
		//Connect�n���h���̔j��
		_InternetCloseHandle hConnect
	} else {
		//Connect�n���h�����擾�ł��Ȃ������ꍇ
		API_statcode = -4
	}
return API_statcode
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
getBody
TwitterAPI���얽�ߎ��s��̌��ʂ��擾

%prm
()

%inst
TwitterAPI���얽�ߎ��s��̉������ʂ�Ԃ��܂��B

%group
TwitterAPI����֐�

%*/
//------------------------------------------------------------
#defcfunc getBody
return ResponseBody
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
getHeader
TwitterAPI���얽�ߎ��s��̃w�b�_���擾

%prm
()

%inst
TwitterAPI���얽�ߎ��s��̃w�b�_��Ԃ��܂��B

%group
TwitterAPI����֐�

%*/
//------------------------------------------------------------
#defcfunc getHeader
return ResponseHeader
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
TS_Init
TsubuyakiSoup�̏�����

%prm
p1, p2, p3
p1 = ������      : ���[�U�G�[�W�F���g
p2 = ������      : Consumer Key
p3 = ������      : Consumer Secret
p4 = 0�`(30)     : �^�C���A�E�g�̎���(�b)

%inst
TsubyakiSoup���W���[���̏����������܂��BTwitter���얽�߂̎g�p�O�ɌĂяo���K�v������܂��B

p1�Ƀ��[�U�G�[�W�F���g���w�肵�܂��B���[�U�G�[�W�F���g���w�肵�Ă��Ȃ���SearchAPI�ȂǂŌ�����API�������󂯂邱�Ƃ�����܂��B

p2��Consumer Key���Ap3��Consumer Secret���w�肵�Ă��������BConsumer Key��Consumer Secret�́ATwitter����擾����K�v������܂��B�ڂ����́A���t�@�����X���������������B

p4�ɂ�Twitter�ƒʐM����ۂ̃^�C���A�E�g�̎��Ԃ�b�P�ʂŎw�肵�Ă��������B

%href
TS_End

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _TS_Init str p1, str p2, str p3, int p4
	//�e��ϐ��̏�����
	TS_RateLimit(0) = -1		//60���Ԃ�API�����s�ł����
	TS_RateLimit(1) = -1		//API�����s�ł���c���
	TS_RateLimit(2) = -1		//���Z�b�g���鎞��
	TS_AccessToken = ""				//AccessToken
	TS_AccessTokenSecret = ""		//AccessTokenSecret
	TS_RequestToken = ""		//RequestToken
	TS_RquestTokenSecret = ""	//RequestTokenSecret
	TS_Consumer_Key = p2		//ConsumerKey
	TS_Consumer_Secret = p3		//ConsumerSecret
	TS_ScreenName = ""
	TS_UserID = 0.0
	TS_FormatType = "json"
	tmpInt = p4*1000
	//�C���^�[�l�b�g�I�[�v��
	TS_hInet = _InternetOpen( p1, INTERNET_OPEN_TYPE_DIRECT, 0, 0, 0)
	//INTERNET_OPTION_CONNECT_TIMEOUT  2
	_InternetSetOption TS_hInet, 2, varptr(tmpInt), 4
	//INTERNET_OPTION_HTTP_DECODING  65
	flag= 1
	_InternetSetOption TS_hInet, 65, varptr(flag), 4
return
#define global TS_Init(%1,%2,%3,%4=30) _TS_Init %1, %2, %3, %4
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
TS_End
TsubuyakiSoup�̏I������

%inst
TsubyakiSoup���W���[���̏I���������s�Ȃ��܂��B
�v���O�����I�����Ɏ����I�ɌĂяo�����̂Ŗ����I�ɌĂяo���K�v�͂���܂���B

%href
TS_Init

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc TS_End onexit
	//�n���h���̔j��
	if (hRequest) : _InternetCloseHandle hRequest
	if (hConnect) : _InternetCloseHandle hConnect
	if (TS_hInet) : _InternetCloseHandle TS_hInet
return
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
SetFormatType
�擾�t�H�[�}�b�g�̐ݒ�

%prm
p1
p1 = 0�`1(0)     : �t���O

%inst
TwitterAPI���얽�ߌn�Ŏ擾����f�[�^�̃t�H�[�}�b�g��ݒ肵�܂��B

p1�ɂ͈ȉ��̃t���O���ݒ�ł��܂��B
    0 : JSON�`���Ŏ擾
    1 : XML�`���Ŏ擾

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _SetFormatType int p1
	TS_FormatType = "json"
	if p1 = 1 : TS_FormatType = "xml"
return
#define global SetFormatType(%1=0) _SetFormatType %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetAuthorizeAdress
�A�N�Z�X�������߂�URL�𐶐�

%prm
()

%inst
���[�U�ɃA�N�Z�X�������߂�A�h���X�𐶐����A�߂�l�Ƃ��ĕԂ��܂��B

������Twitter�ƒʐM���A���N�G�X�g�g�[�N�����擾���Ă��܂��B���N�G�X�g�g�[�N���̎擾�Ɏ��s�����ꍇ�́A"Error"�Ƃ����������Ԃ��܂��B

%group
TwitterAPI����֐�

%*/
//------------------------------------------------------------
#defcfunc GetAuthorizeAdress
	// �A�N�Z�X�g�[�N���擾
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "oauth/request_token", Argument
	if stat != 200 : return "Error"
	// �g�[�N���̎��o��
	;request_token
	TokenStart = instr(ResponseBody, 0, "oauth_token=") + 12
	TokenEnd = instr(ResponseBody, TokenStart, "&")
	TS_RequestToken = strmid(ResponseBody, TokenStart, TokenEnd)
	;request_token_secret
	Token_SecretStart = instr(ResponseBody, 0, "oauth_token_secret=") + 19
	Token_SecretEnd = instr(ResponseBody, Token_SecretStart, "&")
	TS_RquestTokenSecret = strmid(ResponseBody, Token_SecretStart, Token_SecretEnd)
return "http://api.twitter.com/oauth/authorize?oauth_token="+ TS_RequestToken
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
SetAccessToken
AccessToken��Secret��ݒ�

%prm
p1, p2
p1 = ������      : Access Token
p2 = ������      : Access Secret

%inst
TsubuyakiSoup��Access Token��Access Secret��ݒ肵�܂��B

p1��Access Token���Ap2��Access Secret���w�肵�܂��B

����Access Token��Access Secret�́AGetAccessToken���߂�GetxAuthToken���߂Ŏ擾���邱�Ƃ��ł��܂��B�ڂ����́A���t�@�����X���������������B

%href
GetAccessToken
GetxAuthToken

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc SetAccessToken str p1, str p2
	TS_AccessToken = p1
	TS_AccessTokenSecret = p2
return
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
SetUserInfo
���[�U����ݒ�

%prm
p1, p2
p1 = ������      : ���[�U���i�X�N���[�����j
p2 = 0�`         : ���[�UID

%inst
TsubuyakiSoup�Ƀ��[�U���i�X�N���[�����j�ƃ��[�UID��ݒ肵�܂��B

p1�Ƀ��[�U���i�X�N���[�����j���Ap2�Ƀ��[�UID���w�肵�܂��B

���̃��[�U���i�X�N���[�����j�ƃ��[�UID�́AGetAccessToken���߂�GetxAuthToken���߂��g�p���Ď擾���Ă��������B�ڂ����́A���t�@�����X���������������B

%href
GetAccessToken
GetxAuthToken

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc SetUserInfo str p1, double p2
	TS_ScreenName = p1
	TS_UserID = p2
return
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetAccessToken
OAuth��AccessToken��Secret�擾

%prm
p1, p2, p3, p4
p1 = �ϐ�        : Access Token��������ϐ�
p2 = �ϐ�        : Access Secret��������ϐ�
p3 = �ϐ�        : ���[�U����������ϐ�
p4 = ������      : PIN�R�[�h

%inst
TwitterAPI�uoauth/access_token�v�����s���AOAuth������Access Token��Access Secret���擾���܂��B

p1, p2�ɂ��ꂼ��Access Token, Access Secret��������ϐ����w�肵�Ă��������B

p3�ɂ́A���[�U����������ϐ����w�肵�Ă��������B�u���[�UID,���[�U���v�ƃJ���}��؂�Ń��[�U��񂪑������܂��B

p4�ɂ́APIN�R�[�h���w�肵�Ă��������BPIN�R�[�h�́AGetAuthorizeAdress�Ŏ擾����URL�ɃA�N�Z�X���A���[�U���u���v�{�^�����������Ƃ��ɕ\������܂��B�ڂ����́A���t�@�����X���������������B

Access Token��Secret�́A��x�擾����Ɖ��x���g�p���邱�Ƃ��ł��܂��i���݂�Twitter�̎d�l�ł́j�B���̂��߁A��xAccess Token��Secret���擾������ۑ����Ă������Ƃ��������߂��܂��B
�܂��AAccess Token��Secret�̓��[�U���ƃp�X���[�h�̂悤�Ȃ��̂Ȃ̂ŁA�Í������ĕۑ�����ȂǊǗ��ɂ͋C�����Ă��������BOAuth/xAuth�̏ڂ������Ƃ́A���t�@�����X���������������B

%href
GetAuthorizeAdress
GetxAuthToken
SetAccessToken

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc GetAccessToken var p1, var p2, var p3, str p4
	sdim p1
	sdim p2
	sdim p3
	sdim Argument
	Argument(0) = "oauth_token="+ TS_RequestToken
	Argument(1) = "oauth_verifier="+ p4
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "oauth/access_token", Argument
	statcode = stat
	if statcode = 200  {
		//�g�[�N���̎��o��
		;request_token
		TokenStart = instr(ResponseBody, 0, "oauth_token=") + 12
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p1 = strmid(ResponseBody, TokenStart, TokenEnd)
		;request_token_secret
		TokenStart = instr(ResponseBody, 0, "oauth_token_secret=") + 19
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p2 = strmid(ResponseBody, TokenStart, TokenEnd)
		;User���
		TokenStart = instr(ResponseBody, 0, "user_id=") + 8
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p3 = strmid(ResponseBody, TokenStart, TokenEnd) +","
		TokenStart = instr(ResponseBody, 0, "screen_name=") + 12
		TokenEnd = strlen(ResponseBody)
		p3 += strmid(ResponseBody, TokenStart, TokenEnd)
	}
return statcode
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetxAuthToken
xAuth��AccessToken��Secret�擾

%prm
p1, p2, p3, p4, p5
p1 = �ϐ�        : Access Token��������ϐ�
p2 = �ϐ�        : Access Secret��������ϐ�
p3 = �ϐ�        : ���[�U����������ϐ�
p4 = ������      : ���[�U���i�X�N���[�����j
p5 = ������      : �p�X���[�h

%inst
TwitterAPI�uoauth/access_token�v�����s���AxAuth������Access Token��Access Secret���擾���܂��B

p1, p2�ɂ��ꂼ��Access Token, Access Secret��������ϐ����w�肵�Ă��������B

p3�ɂ́A���[�U����������ϐ����w�肵�Ă��������B�u���[�UID,���[�U���v�ƃJ���}��؂�Ń��[�U��񂪑������܂��B

p4�ɂ�Twitter�ł̃��[�U���i�X�N���[�����j���Ap5�ɂ̓p�X���[�h���w�肵�Ă��������B

�F�ؕ�����xAuth���g�p����ɂ́ATwitter��xAuth�̗��p�ɂ��Đ\�������A���F���󂯂�K�v������܂��B�ڂ����́A���t�@�����X���������������B

Access Token��Secret�́A��x�擾����Ɖ��x���g�p���邱�Ƃ��ł��܂��i���݂�Twitter�̎d�l�ł́j�B���̂��߁A��xAccess Token��Secret���擾������ۑ����Ă������Ƃ��������߂��܂��B
�܂��AAccess Token��Secret�̓��[�U���ƃp�X���[�h�̂悤�Ȃ��̂Ȃ̂ŁA�Í������ĕۑ�����ȂǊǗ��ɂ͋C�����Ă��������B�ڂ����́A���t�@�����X���������������B

%href
GetAccessToken
SetAccessToken

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc GetxAuthToken var p1, var p2, var p3, str p4, str p5, local GRT_Password
	GRT_UserName = p4
	GRT_Password = p5
	p3 = ""
	//POST
	sdim Argument
	Argument(0) = "x_auth_mode=client_auth"
	Argument(1) = "x_auth_password=" + GRT_Password
	Argument(2) = "x_auth_username=" + GRT_UserName
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "oauth/access_token", Argument
	statcode = stat
	if statcode = 200  {
		//�g�[�N���̎��o��
		;oauth_token
		TokenStart = instr(ResponseBody, 0, "oauth_token=") + 12
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p1 = strmid(ResponseBody, TokenStart, TokenEnd)
		;oauth_token_secret
		TokenStart = instr(ResponseBody, 0, "oauth_token_secret=") + 19
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p2 = strmid(ResponseBody, TokenStart, TokenEnd)
		;User���
		TokenStart = instr(ResponseBody, 0, "user_id=") + 8
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p3 = strmid(ResponseBody, TokenStart, TokenEnd) +","
		TokenStart = instr(ResponseBody, 0, "screen_name=") + 12
		TokenEnd = instr(ResponseBody, TokenStart, "&")
		p3 += strmid(ResponseBody, TokenStart, TokenEnd)
	}
return statcode
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetHomeTL
�z�[���^�C�����C���̎擾

%prm
p1
p1 = 1�`200(20)  : �擾���錏��

%inst
TwitterAPI�ustatuses/home_timeline�v�����s���A�z�[���^�C�����C����SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%href
GetUserTL
GetMentions
GetRetweetByMe
GetRetweetToMe
GetRetweetOfMe

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetHomeTL int p1
	//����
	sdim Argumet
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/home_timeline."+ TS_FormatType, Argument
return stat
#define global GetHomeTL(%1=20) _GetHomeTL %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetUserTL
���[�U�^�C�����C���̎擾

%prm
p1, p2
p1 = ������      : ���[�U���i�X�N���[�����j
p2 = 1�`200(20)  : �擾���錏��

%inst
TwitterAPI�ustatuses/user_timeline�v�����s���A���[�U�^�C�����C����SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀ^�C�����C�����擾���������[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%href
GetHomeTL
GetMentions
GetRetweetByMe
GetRetweetToMe
GetRetweetOfMe

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetUserTL str p1, int p2
	//����
	sdim Argument
	Argument(0) = "count=" + limit(p2, 1, 200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/user_timeline/"+p1+"."+ TS_FormatType, Argument
return stat
#define global GetUserTL(%1,%2=20) _GetUserTL %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetMentions
�����ɑ΂��錾�y�̎擾

%prm
p1
p1 = 1�`200(20)  : �擾���錏��

%inst
TwitterAPI�ustatuses/mentions�v�����s���A�����ɑ΂��錾�y�i�u@xxxxx�v���܂ރX�e�[�^�X�j��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%href
GetHomeTL
GetUserTL
GetRetweetByMe
GetRetweetToMe
GetRetweetOfMe

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetMentions int p1
	//�J�E���g
	sdim Argument
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/mentions."+ TS_FormatType, Argument
return stat
#define global GetMentions(%1=20) _GetMentions %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetRetweetByMe
���������e�������c�C�[�g�̎擾

%prm
p1
p1 = 1�`200      : �擾���錏��

%inst
TwitterAPI�ustatuses/retweeted_by_me�v�����s���A���������e�������c�C�[�g��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%href
GetHomeTL
GetUserTL
GetMentions
GetRetweetToMe
GetRetweetOfMe

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetRetweetByMe int p1
	//�J�E���g
	sdim Argument
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/retweeted_by_me."+ TS_FormatType, Argument
return stat
#define global GetRetweetByMe(%1=20) _GetRetweetByMe %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetRetweetToMe
������friends�����e�������c�C�[�g�̎擾

%prm
p1
p1 = 1�`200(20)  : �擾���錏��

%inst
TwitterAPI�ustatuses/retweeted_to_me�v�����s���A������friends�����e�������c�C�[�g��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%href
GetHomeTL
GetUserTL
GetMentions
GetRetweetByMe
GetRetweetOfMe

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetRetweetToMe int p1
	//�J�E���g
	sdim Argument
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/retweeted_to_me."+ TS_FormatType, Argument
return stat
#define global GetRetweetToMe(%1=20) _GetRetweetToMe %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetRetweetOfMe
���c�C�[�g���ꂽ�����̓��e���擾

%prm
p1
p1 = 1�`200(20) : �擾���錏��

%inst
TwitterAPI�ustatuses/retweets_of_me�v�����s���A���c�C�[�g���ꂽ�����̓��e��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%href
GetHomeTL
GetUserTL
GetMentions
GetRetweetByMe
GetRetweetToMe

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetRetweetOfMe int p1
	//�J�E���g
	sdim Argument
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/retweets_of_me."+ TS_FormatType, Argument
return stat
#define global GetRetweetOfMe(%1=20) _GetRetweetOfMe %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
Tweet
�c�C�[�g����

%prm
p1, p2
p1 = ������      : �c�C�[�g���镶����
p2 = 0�`(0)      : �ԐM(reply)�Ώۂ̃X�e�[�^�XID

%inst
TwitterAPI�ustatuses/update�v�����s���ATwitter�֓��e���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀc�C�[�g����140���ȓ��̕�������w�肵�Ă��������B140���ȏ�̏ꍇ�A140���Ɋۂ߂Ă���c�C�[�g����܂��B

p2�ɕԐM(reply)�Ώۂ̃X�e�[�^�XID���w�肷�邱�Ƃłǂ̃X�e�[�^�X�ɑ΂���ԐM���𖾎��ł��܂��Bp2��0���w�肷�邩�ȗ������ꍇ�́A��������܂���B
TwitterAPI�̎d�l��A���݂��Ȃ��A���邢�̓A�N�Z�X�����̂������Ă���X�e�[�^�XID���w�肵���ꍇ�ƁAp1�Ŏw�肵��������Ɂu@���[�U���v���܂܂�Ȃ��A���邢��@���[�U���v�Ŏw�肵�����[�U�����݂��Ȃ��ꍇ�́A��������܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂����A1����1000��܂łƂ������s�񐔏�����ݒ肳��Ă��܂�(API�ȊO����̓��e���J�E���g�Ώ�)�B

%href
DelTweet
ReTweet

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _Tweet str p1, str p2
	p11=""
	p22=""
	p11=p1
	p22=p2
	tmpbuf=""
	tmpBuf = p11
	tmpStr = ""
	tmpbuf=str(tmpbuf)
	//�P�S�O���Ɋۂ߂�
	if (mb_strlen(tmpBuf) > 140) {
		tmpBuf = mb_strmid(p11, 0,140)
	}
	//utf-8�֕ϊ��B
	sjis2utf8n tmpStr, tmpBuf
	//POST
	sdim Argument
	Argument(0) = "status="+ form_encode(tmpStr, 1)
	if p2 ! "0" : Argument(1) = "in_reply_to_status_id="+p2+"" 
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "statuses/update."+ TS_FormatType, Argument
return stat
#define global Tweet(%1, %2=0) _Tweet %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
DelTweet
�c�C�[�g���폜����

%prm
p1
p1 = 0�`         : �폜����X�e�[�^�XID

%inst
TwitterAPI�ustatuses/destroy�v�����s���A�w�肳�ꂽ�X�e�[�^�X���폜���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɍ폜����X�e�[�^�XID���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%href
Tweet
ReTweet

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc DelTweet double p1
	//POST
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "statuses/destroy/"+strf("%.0f",p1)+"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
ReTweet
���c�C�[�g����

%prm
p1
p1 = 0�`         : ���c�C�[�g����X�e�[�^�XID

%inst
TwitterAPI�ustatuses/retweet�v�����s���A�w�肳�ꂽ�X�e�[�^�X�����c�C�[�g���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀ��c�C�[�g����X�e�[�^�XID���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂����A1����1000��܂łƂ������s�񐔏�����ݒ肳��Ă��܂�(API�ȊO����̓��e���J�E���g�Ώ�)�B

%href
Tweet
DelTweet

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc ReTweet str p1
	//POST
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "statuses/retweet/"+str(p1)+"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetDirectMessage
�������Ẵ_�C���N�g���b�Z�[�W�̎擾

%prm
p1
p1 = 1�`200(20)  : ����

%inst
TwitterAPI�udirect_messages�v�����s���A�������Ẵ_�C���N�g���b�Z�[�W�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetDirectMessage int p1
	//�J�E���g
	sdim Argument
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "direct_messages."+ TS_FormatType, Argument
return stat
#define global GetDirectMessage(%1=20) _GetDirectMessage %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetDirectMessageSent
�������������_�C���N�g���b�Z�[�W�̎擾

%prm
p1
p1 = 1�`200      : ����

%inst
TwitterAPI�udirect_messages/sent�v�����s���A�������������_�C���N�g���b�Z�[�W�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾���錏�����w�肵�Ă��������BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetDirectMessageSent int p1
	//�J�E���g
	sdim Argument
	Argument(0) = "count=" + limit(p1,1,200)
	//GET
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "direct_messages/sent."+ TS_FormatType, Argument
return stat
#define global GetDirectMessageSent(%1=20) _GetDirectMessageSent %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
NewDirectMessage
�_�C���N�g���b�Z�[�W�𑗐M

%prm
p1, p2
p1 = ������      : ���[�U���i�X�N���[�����j
p2 = ������      : �{��

%inst
TwitterAPI�udirect_messages/new�v�����s���A�w�肳�ꂽ���[�U���Ƀ_�C���N�g���b�Z�[�W�𑗐M���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɉ���̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�ɖ{�����w�肵�Ă��������B�{���́A140���ȓ��ɂ��Ă��������B140���ȏ�̏ꍇ�́A140���ȓ��Ɋۂ߂đ��M����܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂����A1����1000��܂łƂ������s�񐔏�����ݒ肳��Ă��܂�(API�ȊO����̓��e���J�E���g�Ώ�)�B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc NewDirectMessage str p1, str p2
	tmpBuf = p2
	tmpStr = ""
	//�P�S�O���Ɋۂ߂�
	if (mb_strlen(tmpBuf) > 140) {
		tmpBuf = mb_strmid(p1, 0,140)
	}
	;utf-8�֕ϊ��B
	sjis2utf8n tmpStr, tmpBuf
	//POST
	sdim Argument
	Argument(0) = "text="+ form_encode(tmpStr, 1)
	Argument(1) = "user_name="+ p1
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "direct_messages/new."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
DelDirectMessage
�_�C���N�g���b�Z�[�W���폜

%prm
p1
p1 = 0�`         : �_�C���N�g���b�Z�[�WID

%inst
TwitterAPI�udirect_messages/destroy�v�����s���A�w�肳�ꂽ�_�C���N�g���b�Z�[�W���폜���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɍ폜����_�C���N�g���b�Z�[�WID���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc DelDirectMessage double p1
	//POST
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "direct_messages/destroy/"+strf("%.0f",p1)+"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetFriends
friends�̈ꗗ���擾

%prm
p1, p2
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ustatuses/friends�v�����s���A�w�肳�ꂽ���[�U��friends�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃJ�[�\�����w�肵�Ă��������B�J�[�\���ɂ��ẮA���t�@�����X���������������B

p2�ɂ́Afriends�̈ꗗ���擾���������[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ������ꍇ�́A������friends�̈ꗗ���擾���܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetFriends str p1, str p2
	sdim Argument
	Argument(0) = "cursor="+ p1
	if (p2 != "") : Argument(1) = "screen_name="+ p2
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/friends."+ TS_FormatType, Argument
return stat
#define global GetFriends(%1="-1", %2="") _GetFriends %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetFollowers
followers�̈ꗗ���擾

%prm
p1, p2
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ustatuses/followers�v�����s���A�w�肳�ꂽ���[�U��followers�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃJ�[�\�����w�肵�Ă��������B�J�[�\���ɂ��ẮA���t�@�����X���������������B

p2�ɂ́Afollowers�̈ꗗ���擾���������[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ������ꍇ�́A������followers�̈ꗗ���擾���܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetFollowers str p1, str p2
	sdim Argument
	Argument(0) = "cursor="+ p1
	if (p2 != "") : Argument(1) = "screen_name="+ p2
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "statuses/followers."+ TS_FormatType, Argument
return stat
#define global GetFollowers(%1="-1", %2="") _GetFollowers %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
Follow
�w�胆�[�U���t�H���[

%prm
p1
p1 = ������      : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ufiendships/create�v�����s���A�w�肳�ꂽ���[�U���t�H���[���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀt�@���[���郆�[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂����A1����1000��܂łƂ������s�񐔏�����ݒ肳��Ă��܂�(API�ȊO����̓��e���J�E���g�Ώ�)�B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc Follow str p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "friendships/create/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
Remove
�w�胆�[�U�������[�u

%prm
p1
p1 = ������      : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ufiendships/destroy�v�����s���A�w�肳�ꂽ���[�U�������[�u���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀ����[�u���郆�[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc Remove str p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "friendships/destroy/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
FriendShow
���[�U�Ԃ�friend�֌W�𒲂ׂ�

%prm
p1, p2
p1 = 0�`         : ���[�U���i�X�N���[�����j
p2 = 0�`         : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ufriendships/show�v�����s���A�w�肳�ꂽ���[�U�Ԃ�friend�֌W�𒲂ׂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɒ����Ώۂ̂���1�l�ڂ̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ������ꍇ�́A�����Ώۂ͎������g�ɂȂ�B

p2�ɒ����Ώۂ̂���2�l�ڂ̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _FriendShow str p1, str p2
	sdim Argument
	if p1 = "" {
		Argument(0) = "target_screen_name="+ p2
	} else {
		Argument(0) = "source_screen_name="+ p1
		Argument(1) = "target_screen_name="+ p2
	}
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "friendships/show."+ TS_FormatType, Argument
return stat
#define global FriendShow(%1="", %2) _FriendShow %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetFavorite
���C�ɓ���̎擾

%prm
p1, p2
p1 = ������      : ���[�U���i�X�N���[�����j
p2 = 1�`(1)      : �y�[�W��

%inst
TwitterAPI�ufavorites�v�����s���A�w�肳�ꂽ���[�U�̂��C�ɓ���ɓo�^����Ă���c�C�[�g��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɂ��C�ɓ�����擾���������[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�ɂ͎擾����y�[�W�����w�肵�܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetFavorite str p1, int p2
	sdim Argument
	Argument(0) = "page="+ p2
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "favorites/"+ p1 +"."+ TS_FormatType, Argument
return stat
#define global GetFavorite(%1,%2=1)  _GetFavorite %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
AddFavorite
���C�ɓ���ɒǉ�

%prm
p1
p1 = 0�`         : �X�e�[�^�XID

%inst
TwitterAPI�ufavorites/create�v�����s���A�w�肳�ꂽ�c�C�[�g�����C�ɓ���ɓo�^���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɂ��C�ɓ���ɒǉ��������X�e�[�^�XID���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc AddFavorite str p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "favorites/create/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
DelFavorite
���C�ɓ��肩��폜

%prm
p1
p1 = 0�`         : �X�e�[�^�XID

%inst
TwitterAPI�ufavorites/destroy�v�����s���A�w�肳�ꂽ�c�C�[�g�����C�ɓ��肩��폜���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɂ��C�ɓ��肩��폜�������X�e�[�^�XID���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc DelFavorite double p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "favorites/destroy/"+ strf("%.0f",p1) +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
AddBlock
���[�U���u���b�N

%prm
p1
p1 = ������      : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ublocks/create�v�����s���A�w�肳�ꂽ���[�U���u���b�N���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀu���b�N���������[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc AddBlock str p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "blocks/create/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
DelBlock
���[�U���u���b�N����O��

%prm
p1
p1 = ������      : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ublocks/destroy�v�����s���A�w�肳�ꂽ���[�U���u���b�N����O���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀu���b�N����O���������[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc DelBlock str p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "blocks/destroy/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
ExisistBlock
���[�U���u���b�N���Ă��邩���ׂ�

%prm
p1
p1 = ������      : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ublocks/exisits�v�����s���A�w�肳�ꂽ���[�U���u���b�N���Ă��邩���ׂāASetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀu���b�N���Ă��邩���ׂ������[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc ExisistBlock str p1
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "blocks/exisits/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetBlock
�u���b�N���[�U�̈ꗗ���擾

%prm
p1
p1 = 1�`(1)      : �y�[�W��

%inst
TwitterAPI�ublocks/blocking�v�����s���A�������u���b�N���Ă��郆�[�U�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ɏ擾����y�[�W���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetBlock int p1
	sdim Argument
	Argument(0) = "page="+ p1
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "blocks/blocking."+ TS_FormatType, Argument
return stat
#define global GetBlock(%1=1) _GetBlock %1
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetBlockIds
�u���b�N���[�U�̈ꗗ(ID)���擾

%inst
TwitterAPI�ublocks/blocking/ids�v�����s���A�������u���b�N���Ă��郆�[�U�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc GetBlockIds
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "blocks/blocking/ids."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
TwitterTest
Twitter�̏�Ԃ𒲂ׂ�

%inst
TwitterAPI�uhelp/test�v�����s���ATwitter������ɉғ����Ă��邩���ׁASetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc TwitterTest
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, "help/test."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
ReportSpam
���[�U���X�p���Ƃ��ĕ�

%prm
p1
p1 = ������      : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�ureport_spam�v�����s���āA�w�胆�[�U���X�p�}�[�ł���ƕ񍐂��A�u���b�N���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃX�p�}�[�ƕ񍐂��郆�[�U�̃��[�U���i�X�N���[�����j���w�肵�܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc ReportSpam str p1
	sdim Argument
	Argument(0) = "id="+ p1
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, "report_spam."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
CreateList
���X�g���쐬

%prm
p1, p2, p3
p1 = ������      : ���X�g��
p2 = 0�`1(0)     : ���J�͈�
p3 = ������      : ����

%inst
TwitterAPI�����s���A�V�K�Ƀ��X�g���쐬���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ŏw�肵�����O�Ń��X�g���쐬���܂��B�g�p�ł���̂́A�p�����݂̂ł��B

p2�Ń��X�g�̌��J�͈͂��w��ł��܂��B�ȉ��̃t���O���ݒ�ł��܂��B
    0 : ���J (public)
    1 : ����J (private)

p3�ɂ́A���X�g�̐������w�肵�܂��B�w��ł��镶����̒����́A100���܂łł��B100���𒴂����ꍇ�́A���ߑ���100���Ɋۂ߂�TwitterAPI�̈����Ɏw�肵�܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc CreateList str p1, int p2, str p3
	tmpBuf = p3
	tmpStr = ""
	//�P�O�O���Ɋۂ߂�
	if (mb_strlen(tmpBuf) > 100) {
		tmpStr = mb_strmid(p1, 0,100)
	}
	;utf-8�֕ϊ��B
	sjis2utf8n tmpStr, tmpBuf
	sdim Argument
	Argument(1) = "name="+ p1
	Argument(0) = "description="+ form_encode(tmpStr, 1)
	Argument(2) = "mode=public"
	if p2 = 1 : Argument(2) = "mode=private"
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/lists."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
UpdateListName
���X�g�̖��O��ύX

%prm
p1, p2
p1 = ������      : ���X�g��
p2 = ������      : �V�������X�g��

%inst
TwitterAPI�����s���A���X�g�̖��O��ύX���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�Ƀ��X�g�̖��O��ύX���������X�g�����w�肵�Ă��������B

p2�ɐV�������X�g�����w�肵�܂��B�g�p�ł���̂́A�p�����݂̂ł��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc UpdateListName str p1, str p2
	sdim Argument
	Argument(0) = "name="+ p2
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/lists/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
UpdateListMode
���X�g�̌��J�͈͂�ύX

%prm
p1, p2
p1 = ������      : ���X�g��
p2 = 0�`1(0)     : ���J�͈�

%inst
TwitterAPI�����s���A���X�g�̌��J�͈͂�ύX���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

�ύX�����郊�X�g�̖��O��p1�Ɏw�肵�Ă��������B

p2�Ń��X�g�����J�ɂ��邩����J�ɂ��邩�w��ł��܂��B�ȉ��̃t���O���ݒ�ł��܂��B
    0 : ���J (public)
    1 : ����J (private)

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc UpdateListMode str p1, int p2
	sdim Argument
	Argument(0) = "mode=public"
	if p2 = 1 : Argument(0) = "mode=private"
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/lists/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
UpdateListDescription
���X�g�̐�������ύX

%prm
p1, p2, p3
p1 = ������      : ���X�g��
p2 = 0�`1(0)     : ���J�ݒ�
p3 = ������      : ����

%inst
TwitterAPI�����s���A���X�g�̐�������ύX���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

�ύX�����郊�X�g�̖��O��p1�Ɏw�肵�Ă��������B

p2�ɂ́A���X�g�̐������w�肵�܂��B�w��ł��镶����̒�����100���܂łł��B100���𒴂����ꍇ�́A���ߑ���100���Ɋۂ߂�TwitterAPI�̈����Ɏw�肵�܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc UpdateListDescription str p1, str p2
	tmpBuf = p1
	tmpStr = ""
	//�P�O�O���Ɋۂ߂�
	if (mb_strlen(tmpBuf) > 100) {
		tmpBuf = mb_strmid(p1, 0,100)
	}
	;utf-8�֕ϊ��B
	sjis2utf8n tmpStr, tmpBuf
	//POST
	sdim Argument
	Argument(0) = "description="+ form_encode(tmpStr, 1)
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/lists/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetLists
���X�g�̈ꗗ���擾

%prm
p1, p2
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����[�U�̃��X�g�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B�������g�̃��X�g�̈ꗗ���擾����ꍇ�́A����J�̃��X�g���܂܂�܂��B

p1�ɃJ�[�\�����w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ATwitterAPI�̈�����"-1"��n���܂��B�J�[�\���̏ڍׂɂ��Ă̓��t�@�����X���������������B

p2�ɂ̓��X�g�̈ꗗ���擾���������[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ASetUserInfo���߂œo�^�������[�U���i�X�N���[�����j���g�p���܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetLists str p1, str p2
	AddAdress = p2
	if p2 = "" : AddAdress = TS_ScreenName
	sdim Argument
	Argument(0) = "cursor="+ p1
	if p1 = "" : Argument(0) = "cursor=-1"
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, AddAdress +"/lists."+ TS_FormatType, Argument
return stat
#define global GetLists(%1="-1",%2="") _GetLists %1, $2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetListInfo
���X�g�̏����擾

%prm
p1, p2
p1 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��

%inst
TwitterAPI�����s���A�w�肵�����[�U�̃��X�g�̏���SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B�������g�̃��X�g���w�肵���ꍇ�́A����J�̃��X�g�ł��擾�ł��܂��B

p1�ɂ̓��X�g�̏����擾���������[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ASetUserInfo���߂œo�^�������[�U���i�X�N���[�����j���g�p���܂��B

p2�ɂ͏����擾���郊�X�g�̃��X�g�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetListInfo str p1, str p2
	AddAdress = p1
	if p1 = "" : AddAdress = TS_ScreenName
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, AddAdress +"/lists/"+ p2 +"."+ TS_FormatType, Argument
return stat
#define global GetListInfo(%1="", %2) _GetListInfo %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
DelList
���X�g���폜

%prm
p1
p1 = ������        : ���X�g��

%inst
TwitterAPI�����s���A�w�肵�����X�g���폜���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɍ폜���������X�g�̃��X�g�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc DelList str p1
	sdim Argument
	Argument(0) = "_method=DELETE"
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/lists/"+ p1 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetListStatus
���X�g�̃^�C�����C���擾

%prm
p1, p2, p3
p1 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��
p3 = 1�`200(20)    : ����

%inst
TwitterAPI�����s���A�w�肵�����[�U�̃��X�g�̃^�C�����C����SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɑΏۃ��[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́A�������g���ΏۂɂȂ�܂��B

p2�ɂ͎擾���������X�g�̃��X�g�����w�肵�Ă��������B

p3�ɂ͎擾���錏�������Ă��܂��BTwitterAPI�̎d�l��A�w��ł���̂�200���܂łł��B200�ȏ���w�肵�Ă�200���܂ł����擾�ł��܂���B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetListStatus str p1, str p2, int p3
	sdim Argument
	Argument(0) = "per_page="+ limit(p3, 1, 200)
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, p1 +"/lists/"+ p2 +"/statuses."+ TS_FormatType, Argument
return stat
#define global GetListStatus(%1=TS_ScreenName@TsubuyakiSoup,%2,%3=20) _GetListStatus %1, %2, %3
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetEntryList
�t�H���[����Ă郊�X�g�̈ꗗ���擾

%prm
p1, p2
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����[�U���t�H���[����Ă��郊�X�g�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃJ�[�\�����w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ATwitterAPI�̈�����"-1"��n���܂��B�J�[�\���̏ڍׂɂ��Ă̓��t�@�����X���������������B

p2�ɂ͑Ώۃ��[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ASetUserInfo���߂œo�^�������[�U���i�X�N���[�����j���g�p���܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetEntryList str p1, str p2
	AddAdress = p2
	if p2 = "" : AddAdress = TS_ScreenName
	sdim Argument
	Argument(0) = "cursor="+ p1
	if p1 = "" : Argument(0) = "cursor=-1"
	RESTAPI ResopnseBody, ResponseHeader, METHOD_GET, AddAdress +"/lists/memberships."+ TS_FormatType, Argument
return stat
#define global GetEntryList(%1="-1",%2="") _GetEntryList %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetFollowList
�t�H���[���Ă��郊�X�g�̈ꗗ���擾

%prm
p1, p2
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����[�U���t�H���[����Ă��郊�X�g�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃJ�[�\�����w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ATwitterAPI�̈�����"-1"��n���܂��B�J�[�\���̏ڍׂɂ��Ă̓��t�@�����X���������������B

p2�ɂ͑Ώۃ��[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ASetUserInfo���߂œo�^�������[�U���i�X�N���[�����j���g�p���܂��B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetFollowList str p1, str p2
	AddAdress = p2
	if p2 = "" : AddAdress = TS_ScreenName
	sdim Argument
	Argument(0) = "cursor="+ p1
	if p1 = "" : Argument(0) = "cursor=-1"
	RESTAPI ResopnseBody, ResponseHeader, METHOD_GET, AddAdress +"/lists/subscriptions."+ TS_FormatType, Argument
return stat
#define global GetFollowList(%1="-1",%2="") _GetFollowList %1, %2
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetListMembers
���X�g�̃����o�[�̈ꗗ

%prm
p1, p2, p3
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��

%inst
TwitterAPI�����s���A�w�肵�����[�U�̃��X�g���t�H���[���Ă��郆�[�U�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃJ�[�\�����w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ATwitterAPI�̈�����"-1"��n���܂��B�J�[�\���̏ڍׂɂ��Ă̓��t�@�����X���������������B

p2�ɂ́A�Ώۃ��[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p3�ɂ́A�ꗗ���擾���������X�g�̃��X�g�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetListMembers str p1, str p2, str p3
	sdim Argument
	Argument(0) = "cursor="+ p1
	if p1 = "" : Argument(0) = "cursor=-1"
	//GET
	RESTAPI ResopnseBody, ResponseHeader, METHOD_GET, p2 +"/"+ p3 +"/members."+ TS_FormatType, Argument
return stat
#define global GetListMembers(%1="-1",%2,%3) _GetListMembers %1, %2, %3
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
AddListMember
���X�g�Ƀ����o�[��ǉ�

%prm
p1, p2
p1 = ������        : ���X�g��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����X�g�Ƀ����o�[��ǉ����܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɂ͒ǉ��惊�X�g�̃��X�g�����w�肵�Ă��������B

p2�ɂ́A�ǉ����郆�[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc AddListMember str p1, str p2
	sdim Argument
	Argument(0) = "id="+ p2
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/"+ p1 +"/members."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
DelListMember
���X�g���烁���o�[���폜

%prm
p1, p2
p1 = ������        : ���X�g��
p2 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����X�g���烁���o�[���폜���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɂ͍폜�����X�g�̃��X�g�����w�肵�Ă��������B

p2�ɂ́A�폜���郆�[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc DelListMember str p1, str p2
	sdim Argument
	Argument(0) = "id="+ p2
	Argument(1) = "_method=DELETE"
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, TS_ScreenName +"/"+ p1 +"/members."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
IsListMember
���X�g�̃����o�[�����ׂ�

%prm
p1, p2, p3
p1 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��
p3 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����[�U���A�w�肵�����X�g�̃����o�[�ł��邩�ǂ����𒲂ׂ܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B
���X�g�̃����o�[�̏ꍇ�́A���̃��[�U�Ɋւ����񂪕Ԃ�܂��B

p1�ɑΏۃ��X�g�̍쐬�҂̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�ɂ́A�Ώۃ��X�g�̃��X�g�����w�肵�Ă��������B

p3�ɂ́A�Ώۃ��[�U�̃��[�U�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc IsListMember str p1, str p2, str p3
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, p1 +"/"+ p2 +"/members/"+ p3 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
GetListFollowers
���X�g�̃t�H�����[�̈ꗗ

%prm
p1, p2, p3
p1 = ������("-1")  : �J�[�\��
p2 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��

%inst
TwitterAPI�����s���A�w�肵�����[�U�̃��X�g���t�H���[���Ă��郆�[�U�̈ꗗ��SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɃJ�[�\�����w�肵�Ă��������B�ȗ����ꂽ�ꍇ�́ATwitterAPI�̈�����"-1"��n���܂��B�J�[�\���̏ڍׂɂ��Ă̓��t�@�����X���������������B

p2�ɂ́A�Ώۃ��[�U�̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p3�ɂ́A�ꗗ���擾���������X�g�̃��X�g�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc _GetListFollowers str p1, str p2, str p3
	sdim Argument
	Argument(0) = "cursor="+ p1
	if p1 = "" : Argument(0) = "cursor=-1"
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, p2 +"/"+ p3 +"/subscribers."+ TS_FormatType, Argument
return stat
#define global GetListFollowers(%1="-1",%2,%3) _GetListFollowers %1, %2, %3
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
FollowList
���X�g���t�H���[

%prm
p1, p2
p1 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��

%inst
TwitterAPI�����s���A�w�肵�����X�g���t�H���[���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɑΏۃ��X�g�̍쐬�҂̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�ɂ́A�t�H���[���郊�X�g�̃��X�g�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc FollowList str p1, str p2
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, p1 +"/"+ p2 +"/subscribers."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
RemoveList
���X�g�������[�u

%prm
p1, p2
p1 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��

%inst
TwitterAPI�����s���A�w�肵�����X�g���t�H���[���܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B

p1�ɑΏۃ��X�g�̍쐬�҂̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�ɂ́A�����[�u���郊�X�g�̃��X�g�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc RemoveList str p1, str p2
	sdim Argument
	Argument(0) = "_method=DELETE"
	RESTAPI ResponseBody, ResponseHeader, METHOD_POST, p1 +"/"+ p2 +"/subscribers."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
IsListFollower
���X�g�̃t�H�����[�����ׂ�

%prm
p1, p2, p3
p1 = ������        : ���[�U���i�X�N���[�����j
p2 = ������        : ���X�g��
p3 = ������        : ���[�U���i�X�N���[�����j

%inst
TwitterAPI�����s���A�w�肵�����[�U���A�w�肵�����X�g�̃t�H�����[�ł��邩�ǂ����𒲂ׂ܂��B���ʂ�SetFormatType���߂Ŏw�肵���t�H�[�}�b�g�Ŏ擾���܂��B�f�t�H���g��XML�`���ł��B
���X�g�̃t�H�����[�̏ꍇ�́A���̃��[�U�Ɋւ����񂪕Ԃ�܂��B

p1�ɑΏۃ��X�g�̍쐬�҂̃��[�U���i�X�N���[�����j���w�肵�Ă��������B

p2�ɂ́A�Ώۃ��X�g�̃��X�g�����w�肵�Ă��������B

p3�ɂ́A�Ώۃ��[�U�̃��[�U�����w�肵�Ă��������B

TwitterAPI�����s�����ۂ̃X�e�[�^�X�R�[�h�̓V�X�e���ϐ�stat�ɑ������܂��B
���s���ĕԂ��Ă��������́AgetBody�֐���getHeader�֐��ŎQ�Ƃ��邱�Ƃ��ł��܂��B

API�����K�p�Ώۂ�API���g�p���Ă��܂��B

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc IsListFollower str p1, str p2, str p3
	sdim Argument
	RESTAPI ResponseBody, ResponseHeader, METHOD_GET, p1 +"/"+ p2 +"/subscribers/"+ p3 +"."+ TS_FormatType, Argument
return stat
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
RateLimit
API�����󋵂�Ԃ�

%prm
(p1, p2)
p1 = 0�`2        : �擾����f�[�^�̎��
p2 = 0�`1        : �擾������@

%inst
API�����󋵂�Ԃ��܂��B

p1�Ɏ擾����f�[�^�̎�ނ��w�肵�܂��B���L�̃t���O���ݒ�ł��܂��B
    0 : 60���Ԃ�API�����s�ł����
    1 : API�����s�ł���c���
    2 : API���s�񐔂����Z�b�g����鎞��(UTC)

p2�ɂ͎擾������@���w�肵�܂��B���L�̃t���O���ݒ�ł��܂��B
    0 : API(rate_limit_status)�����s���擾
    1 : �Ō��API�����s�����ۂ̃w�b�_����擾

p2�� 1 ���w�肵���ꍇ�ł��A���̊֐��g�p�O��TwitterAPI�����s���Ă��Ȃ������Ƃ��́ATwitterAPI�urate_limit_status�v���g�p���܂��B

API�����K�p�ΏۊO��API���g�p���Ă��܂��B�iAPI�g�p���j

%group
TwitterAPI����֐�

%*/
//------------------------------------------------------------
#defcfunc RateLimit int p1, int p2
	//�����̃`�F�b�N
	DataKind = p1
	if ((p1 < 0) or (p1 > 2)) : DataKind = 0
	//API(rate_limit_status)�����s
	if ( (p2 != 1) or (TS_RateLimit(0) = -1) ) {
		sdim Argument
		RESTAPI LocalBody, LocalHeader, METHOD_GET, "account/rate_limit_status.xml", Argument
		statcode = stat
		if statcode = 200 {
			newcom oDom,"Microsoft.XMLDOM"
			oDom("async")="False"
			oDom->"loadXML" LocalBody
			oRoot = oDom("documentElement")
			if (varuse(oRoot)) {
				//60���Ԃ�API�����s�ł����
				comres RateLimitElement
				oDom->"getElementsByTagName" "hourly-limit"
				node = RateLimitElement("item",0)
				TS_RateLimit(0) = int(node("text"))
				//API�����s�ł���c���
				comres RateLimitElement
				oDom->"getElementsByTagName" "remaining-hits"
				node = RateLimitElement("item",0)
				TS_RateLimit(1) = int(node("text"))
				//API���s�񐔂����Z�b�g����鎞��
				comres RateLimitElement
				oDom->"getElementsByTagName" "reset-time-in-seconds"
				node = RateLimitElement("item",0)
				TS_RateLimit(2) = int(node("text"))
				//�㏈��
				delcom node
				delcom RateLimitElement
				delcom oRoot
			}
			delcom oDom
		}
	}
return TS_RateLimit(DataKind)
//============================================================




//============================================================
/*  [HDL symbol infomation]

%index
TwitterSearch
�X�e�[�^�X������

%prm
p1
p1 = �z��      : API�ɓY�����������������������z��

%inst
SearchAPI�usearch�v�����s���ATwitter���̃X�e�[�^�X���������āA�������ʂ�JSON�`���Ŏ擾���܂��B

SearchAPI�ɓn�������𕶎���^�̔z��ɂ���p1�Ɏw�肵�܂��B
�Ⴆ�΁AAPI"search"�Ɉ���"q=hsp"��"rpp=50"���w�肵�āA"hsp"���܂܂ꂽ�X�e�[�^�X���������A50���擾����Ƃ��܂��B
    Argument(0) = "q=hsp"
    Argument(1) = "rpp=50"
    TwitterSearch Argument

TS_Init�Ń��[�U�G�[�W�F���g���w�肵�Ă��Ȃ��ꍇ�A������API�������󂯂邱�Ƃ�����܂��B

%href
SearchAPI

%group
TwitterAPI���얽��

%*/
//------------------------------------------------------------
#deffunc TwitterSearch array p1
	SearchAPI ResponseBody, ResponseHeader, "search.json", p1
return stat
//============================================================



//============================================================
/*  [HDL symbol infomation]

%index
json_sel
JSON�`���̕������I��

%prm
p1
p1 = JSON�`���̕�����

%inst
JSON�`���̕������I�����܂��B

�I����Ajson_unsel���߂���������܂�json_val�֐��Ajson_length�֐��̑ΏۂƂȂ�܂��B

%href
json_val
json_length
json_unsel

%group
JSON�p�[�T

%*/
//------------------------------------------------------------
#deffunc json_sel str p1
	if vartype(mssc) != vartype("comobj") {
		newcom mssc, "MSScriptControl.ScriptControl"
		mssc("Language") = "JScript"
	}
	sdim tmp, strlen(p1)+1
	sdim jsontext, strlen(p1)+1
	tmp = p1
	jsontext = utf8n2sjis(tmp)
	sdim tmp, 0
	mssc -> "addCode" "obj = "+ jsontext +";"
return
//============================================================



//============================================================
/*  [HDL symbol infomation]

%index
json_val
�w�肵���z��̗v�f�̓��e��Ԃ�

%prm
p1
p1 = �v�f�̈ʒu

%inst
p1�Ŏw�肳�ꂽ�v�f�̓��e��Ԃ��܂��B

%href
json_sel
json_length
json_unsel

%group
JSON�p�[�T

%*/
//------------------------------------------------------------
#defcfunc json_val str p1
	comres result
	mssc -> "Eval" "obj"+ p1 +" === null"
	if (result == -1) : return ""
	mssc -> "Eval" "obj"+ p1
return result
//============================================================



//============================================================
/*  [HDL symbol infomation]

%index
json_length
�z��̗v�f����Ԃ�

%prm
p1
p1 = �v�f�̈ʒu

%inst
p1�Ŏw�肳�ꂽ�I�u�W�F�N�g�̗v�f����Ԃ��܂��B

%href
json_sel
json_val
json_unsel

%group
JSON�p�[�T

%*/
//------------------------------------------------------------
#defcfunc json_length str p1
	comres result
	mssc -> "Eval" "obj"+ p1 +".length"
return result
//============================================================



//============================================================
/*  [HDL symbol infomation]

%index
json_unsel
JSON�`���̕�����̑I������������

%prm


%inst
json_sel�Ŏw�肳�ꂽJSON�`���̕�������p�[�X�Ώۂ���O���܂��B

%href
json_sel
json_val
json_length

%group
JSON�p�[�T

%*/
//------------------------------------------------------------
#deffunc json_unsel
	sdim jsontext,0
return
//============================================================


#global





// �����񑀍샂�W���[��
#module mod_string

#uselib "kernel32.dll"
#cfunc _MultiByteToWideChar "MultiByteToWideChar" int, int, sptr, int, int, int

/*------------------------------------------------------------*/
//1�o�C�g�E2�o�C�g����
//
//	Is_Byte(p1)
//		p1...���ʕ����R�[�h
//		[0.1byte/1,2byte]
//

#defcfunc Is_Byte int p1
return (p1>=129 and p1<=159) or (p1>=224 and p1<=252)
/*------------------------------------------------------------*/

#defcfunc mb_strlen str p1
return _MultiByteToWideChar(0, 0, p1, -1, 0, 0)-1


#deffunc SortString array p1
	loopMax = length(p1) - 1
	repeat loopMax
		repeat loopMax - cnt
			a_pos = 0
			b_pos = 0
			elm_pos = loopMax - cnt
			a_len = strlen(p1(elm_pos))
			b_len = strlen(p1(elm_pos-1))
			if (a_len < b_len) { StrLenMin = a_len : Longer = 0 } else { StrLenMin = b_len : Longer = 1 }
			repeat StrLenMin
				a_buf = peek( p1(elm_pos), a_pos)
				if (Is_Byte(a_buf)) : a_buf = wpeek(p1(elm_pos), a_pos) : a_pos++
				a_pos++
				b_buf = peek( p1(elm_pos-1), b_pos)
				if (Is_Byte(b_buf)) : b_buf = wpeek(p1(elm_pos-1), b_pos) : b_pos++
				b_pos++
				if a_buf > b_buf : break
				if a_buf < b_buf : buf = p1(elm_pos) : p1(elm_pos) = p1(elm_pos-1) : p1(elm_pos-1) = buf
			loop
			if (a_buf = b_buf) and (Longer = 0) : buf = p1(elm_pos) : p1(elm_pos) = p1(elm_pos-1) : p1(elm_pos-1) = buf
		loop
	loop
return


/*------------------------------------------------------------*/
//���p�E�S�p�܂߂������������o��
//
//	mb_strmid(p1, p2, p3)
//		p1...���o�����Ƃ̕����񂪊i�[����Ă���ϐ���
//		p2...���o���n�߂̃C���f�b�N�X
//		p3...���o��������
//

#defcfunc mb_strmid var p1, int p2, int p3
	if vartype(p1) != 2 : return ""
	s_size = strlen(p1)
	trim_start = 0
	trim_num = 0
	repeat p2
		if (Is_Byte(peek(p1,trim_start))) : trim_start++
		trim_start++
	loop
	repeat p3
		if (Is_Byte(peek(p1,trim_start+trim_num))) : trim_num++
		trim_num++
	loop
return strmid(p1,trim_start,trim_num)


//p2 ���p�X�y�[�X�̏���  0 : '&'  1 : '%20'
#defcfunc form_encode str p1, int p2
/*
09 az AZ - . _ ~
�͂��̂܂܏o��
*/
fe_str = p1
fe_p1Long = strlen(p1)
sdim fe_val, fe_p1Long*3
repeat fe_p1Long
	fe_flag = 0
	fe_tmp = peek(fe_str, cnt)
	if (('0' <= fe_tmp)&('9' >= fe_tmp)) | (('A' <= fe_tmp)&('Z' >= fe_tmp)) | (('a' <= fe_tmp)&('z' >= fe_tmp)) | (fe_tmp = '-') | (fe_tmp = '.') | (fe_tmp = '_') | (fe_tmp = '~') :{
		poke fe_val, strlen(fe_val), fe_tmp
	} else {
		if fe_tmp = ' ' {
			if p2 = 0 : fe_val += "&"
			if p2 = 1 : fe_val += "%20"	//�󔒏���
		} else {
			fe_val += "%" + strf("%02X",fe_tmp)
		}
	}
loop
return fe_val


//�����_���ȕ�����𔭐�������
//p1����p2�����܂�33-
#defcfunc RandomString int p1, int p2
;randomize
RS_Strlen = rnd(p2-p1+1) + p1
sdim RS_val, RS_Strlen
repeat RS_Strlen
	RS_rnd = rnd(3)
	if RS_rnd = 0 : RS_s = 48 + rnd(10)
	if RS_rnd = 1 : RS_s = 65 + rnd(26)
	if RS_rnd = 2 : RS_s = 97 + rnd(26)
	poke RS_val, cnt, RS_s
loop
return RS_val

//BASE64�֕ϊ�
#defcfunc Base64Encode str p1
	buf = p1
	bufSize = strlen(buf)
	val = ""
	B64Table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	cc = 0
	frac = bufSize\3
	repeat bufSize/3
		repeat 3
			b(cnt) = peek(buf, cc*3+cnt)
		loop
		val += strmid(B64Table, (b(0) >> 2), 1)
		val += strmid(B64Table, ((b(0) & 3) << 4) + (b(1) >> 4), 1)
		val += strmid(B64Table, ((b(1) & 15) << 2) + (b(2) >> 6), 1)
		val += strmid(B64Table, (b(2) & 63), 1)
		cc++
	loop
	//�[����
	if (frac) {
		memexpand buf, bufSize+3
		repeat 3
			b(cnt) = peek(buf, cc*3+cnt)
		loop
		val += strmid(B64Table, b(0) >> 2, 1)
		if (frac >= 1) : val += strmid( B64Table, ((b(0) & %00000011) << 4) + (b(1) >> 4), 1)
		if (frac >= 2) : val += strmid( B64Table, ((b(1) & %00001111) << 2) + (b(2) >> 6), 1)
	}
	repeat (4-(strlen(val)\4))\4
		val += "="
	loop
return val

#global

