$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$symbols=New-Object 'System.Collections.Generic.Dictionary[string,int]'
Get-Content (Join-Path $root 'wifi_setup_next.sym') | ForEach-Object {
 if ($_ -match '^v0\.([^:]+): EQU 0x([0-9A-Fa-f]+)') { $symbols[$matches[1]]=[Convert]::ToInt32($matches[2],16) }
}
Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Collections.Generic;
public class ApCpu {
 public byte[] M=new byte[65536]; public Dictionary<string,int> S;
 public int A,B,C,D,E,H,L,F,AltA,AltF,PC,SP=0x6800,IX,Steps,Idle; public bool Failed;
 public bool ContinuePrompt,InjectError28; public int RestoredSpeed=-1,SpeedManagementCalls,AkeyCalls; public int BootIdle; public string PingReply="\r\n+23\r\nOK\r\n"; public int InputKey=13; public string ScanReply=""; public bool Done; public string Scenario="",Auto="1",Mode="1",Boot="normal";
 public List<string> Commands=new List<string>(); public List<string> Messages=new List<string>();
 Queue<int> Q=new Queue<int>();
 int HL {get{return H*256+L;}set{H=(value>>8)&255;L=value&255;}}
 int DE {get{return D*256+E;}set{D=(value>>8)&255;E=value&255;}}
 int BC {get{return B*256+C;}set{B=(value>>8)&255;C=value&255;}}
 bool Z {get{return (F&64)!=0;}}
 void Flag(int v){F=(F&1)|((v&65535)==0?64:0);}
 int Byte(){return M[PC++];} int Word(){int v=Byte();return v+256*Byte();}
 void Push(int v){M[--SP]=(byte)(v>>8);M[--SP]=(byte)v;}
 int Pop(){int v=M[SP++];return v+256*M[SP++];}
 int Get(int n){switch(n){case 0:return B;case 1:return C;case 2:return D;case 3:return E;case 4:return H;case 5:return L;case 6:return M[HL];default:return A;}}
 void Set(int n,int v){v&=255;switch(n){case 0:B=v;break;case 1:C=v;break;case 2:D=v;break;case 3:E=v;break;case 4:H=v;break;case 5:L=v;break;case 6:M[HL]=(byte)v;break;default:A=v;break;}}
 public string Str(int p){int n=p;while(M[n]!=0 && n-p<512)n++;return Encoding.ASCII.GetString(M,p,n-p);}
 public void Put(int p,string s){byte[] b=Encoding.ASCII.GetBytes(s+"\0");Array.Copy(b,0,M,p,b.Length);}
 public ApCpu(byte[] bin,Dictionary<string,int> sy){S=sy;Array.Copy(bin,0,M,0xC000,bin.Length);IX=S["flag1"];M[IX+7]=14;}
 void Enqueue(string s){foreach(byte b in Encoding.ASCII.GetBytes(s))Q.Enqueue(b);}
 bool Hook(){if(PC==S["ap_join_prompt"]&&!ContinuePrompt){Done=true;return true;}
if(PC==S["akey"]){AkeyCalls++;PC=Pop();return true;}
if(PC==S["kl2"]){Done=true;return true;}
if(PC==S["speed_management"]){SpeedManagementCalls++;if(InjectError28){Failed=true;Done=true;}else PC=Pop();return true;}
if(PC==S["set_ud_speed_a"]){RestoredSpeed=A;F=64;PC=Pop();return true;} if(PC==S["INPUT"]){A=InputKey;F=0;PC=Pop();return true;} if(PC==S["uf3"]){Messages.Add(Str(DE));PC=Pop();return true;} if(PC==S["key_loop"]){Done=true;return true;}
  if(PC==S["rece_byte"]){if(Q.Count>0){int v=Q.Dequeue();if(v<0){A=0;F=64;}else{A=v;F=0;}}else{A=0;F=64;}PC=Pop();return true;}
  if(PC==S["send_string"]){string c=Str(HL);Commands.Add(c.Trim());F=64;
   if(c.StartsWith("AT+PING=")){Enqueue(PingReply);}else if(c.StartsWith("AT+CWJAP_CUR=")){
    if(Scenario=="timeout"){}else if(Scenario=="wrong")Enqueue("\r\n+CWJAP:2\r\nFAIL\r\n");
    else if(Scenario=="reject")Enqueue("\r\n+CWJAP:4\r\nFAIL\r\n");
    else if(Scenario=="error")Enqueue("\r\nERROR\r\n");
    else Enqueue(c+"\r\nWIFI CONNECTED\r\nWIFI GOT IP\r\nOK\r\n");
   }else if(c.StartsWith("AT+CWJAP_DEF=")){Enqueue(Scenario=="commitfail"?"\r\nFAIL\r\n":"\r\nOK\r\n");}
   else if(c=="AT+CWMODE=1\r\n"||c=="AT+CWLAPOPT=1,6\r\n"||c.StartsWith("AT+CWHOSTNAME="))Enqueue("\r\nOK\r\n"); else if(c=="AT+CWLAP\r\n")Enqueue(ScanReply); else if(c=="AT+CWMODE?\r\n")Enqueue("\r\n+CWMODE:"+Mode+"\r\nOK\r\n");
   else if(c=="AT+CWAUTOCONN?\r\n")Enqueue("\r\n+CWAUTOCONN:"+Auto+"\r\nOK\r\n");
   else if(c=="AT+CWAUTOCONN=1\r\n"){Auto="1";Enqueue("\r\nOK\r\n");}
   else if(c=="AT+CWAUTOCONN=0\r\n"){Auto="0";Enqueue("\r\nOK\r\n");}
   else if(c=="AT+RST\r\n"){
    if(Boot=="delayed"){Enqueue("\r\nOK\r\nready\r\n");QueueIdle(BootIdle);Enqueue("WIFI CONNECTED\r\nWIFI GOT IP\r\n");}else if(Boot=="silent"){}else if(Boot=="earlyip")Enqueue("\r\nOK\r\nWIFI GOT IP\r\nready\r\n");
    else {Enqueue("\r\nOK\r\nready\r\n");if(Boot!="offline")Enqueue("WIFI CONNECTED\r\nWIFI GOT IP\r\n");}
   }else if(c.StartsWith("AT+CWMODE_CUR=")){
    Enqueue("\r\nOK\r\n");if(Boot!="offline" && Boot!="earlyip")Enqueue("WIFI CONNECTED\r\nWIFI GOT IP\r\n");
   }else throw new Exception("Unexpected command: "+c);
   PC=Pop();return true;
  }
  if(PC==S["clear_rece_buf"]){Q.Clear();PC=Pop();return true;}
  if(PC==S["set_def_wifi_speed"]){Put(S["TX_buf"],"speed routine overwrites TX");PC=Pop();return true;}
  if(PC==S["PRINT"]){Messages.Add(Str(DE));PC=Pop();return true;} if(PC==S["read_cwmode"]){PC=Pop();return true;} if(PC==S["poi3"]){Done=true;return true;} if(PC==S["PRINTHL"]){Messages.Add(Str(DE));PC=Pop();return true;}
  foreach(string n in new[]{"wifi_wait","wifi_unwait","clear_edit_zone","undraw_cursor","wind_cls","cls_9_lines"})if(PC==S[n]){PC=Pop();return true;}
  if(PC==S["read_cwhostname"]){PC=Pop();return true;} if(PC==S["klAP_ret"]){Done=true;return true;} if(PC==S["error_handler"]){Failed=true;Done=true;return true;} if(PC==S["cwjap_ret2"]){Done=true;return true;}
  return false;
 }
 public void Run(string entry){PC=S[entry];Push(0x6000);while(!Done && PC!=0x6000){if(++Steps>500000)throw new Exception("Instruction limit at "+PC.ToString("X"));if(Hook())continue;int op=Byte(),v,n;
  if(op>=0x40 && op<=0x7F && op!=0x76){Set((op>>3)&7,Get(op&7));continue;}
  if((op&0xC7)==0x06){Set((op>>3)&7,Byte());continue;}
  if((op&0xC7)==0x04){n=(op>>3)&7;v=(Get(n)+1)&255;Set(n,v);Flag(v);continue;}
  if((op&0xC7)==0x05){n=(op>>3)&7;v=(Get(n)-1)&255;Set(n,v);Flag(v);continue;}
  switch(op){
   case 0x08:v=A;A=AltA;AltA=v;v=F;F=AltF;AltF=v;break;case 0x01:BC=Word();break;case 0x11:DE=Word();break;case 0x21:HL=Word();break;case 0x31:SP=Word();break;
   case 0x09:case 0x19:case 0x29:n=HL+(op==0x09?BC:op==0x19?DE:HL);HL=n&65535;F=(F&64)|(n>65535?1:0);break;case 0x10:v=(sbyte)Byte();B=(B-1)&255;if(B!=0)PC+=v;break;case 0x03:BC=(BC+1)&65535;break;case 0x0B:BC=(BC-1)&65535;break;
   case 0x13:DE=(DE+1)&65535;break;case 0x1B:DE=(DE-1)&65535;break;
   case 0x23:HL=(HL+1)&65535;break;case 0x2B:HL=(HL-1)&65535;break;
   case 0x12:M[DE]=(byte)A;break;case 0x1A:A=M[DE];break;
   case 0x22:n=Word();M[n]=(byte)L;M[n+1]=(byte)H;break;
   case 0x2A:n=Word();HL=M[n]+256*M[n+1];break;
   case 0x32:M[Word()]=(byte)A;break;case 0x3A:A=M[Word()];break;
   case 0xAF:A=0;F=64;break;
   case 0xB0:case 0xB1:case 0xB2:case 0xB3:case 0xB4:case 0xB5:case 0xB6:case 0xB7:A|=Get(op&7);F=A==0?64:0;break;
   case 0xFE:v=Byte();F=(A==v?64:0)|(A<v?1:0);break;
   case 0xB8:case 0xB9:case 0xBA:case 0xBB:case 0xBC:case 0xBD:case 0xBE:case 0xBF:v=Get(op&7);F=(A==v?64:0)|(A<v?1:0);break;
   case 0xF6:A|=Byte();F=A==0?64:0;break;case 0x37:F|=1;break;
   case 0x18:case 0x20:case 0x28:case 0x30:case 0x38:v=(sbyte)Byte();if(op==0x18||(op==0x20&&!Z)||(op==0x28&&Z)||(op==0x30&&(F&1)==0)||(op==0x38&&(F&1)!=0))PC+=v;break;
   case 0xC3:case 0xC2:case 0xCA:case 0xD2:case 0xDA:v=Word();if(op==0xC3||(op==0xC2&&!Z)||(op==0xCA&&Z)||(op==0xD2&&(F&1)==0)||(op==0xDA&&(F&1)!=0))PC=v;break;
   case 0xCD:case 0xC4:case 0xCC:v=Word();if(op==0xCD||(op==0xC4&&!Z)||(op==0xCC&&Z)){Push(PC);PC=v;}break;
   case 0xD8:if((F&1)!=0)PC=Pop();break;case 0xD0:if((F&1)==0)PC=Pop();break;case 0xC9:PC=Pop();break;case 0xC0:if(!Z)PC=Pop();break;case 0xC8:if(Z)PC=Pop();break;
   case 0xC5:Push(BC);break;case 0xD5:Push(DE);break;case 0xE5:Push(HL);break;case 0xF5:Push(A*256+F);break;
   case 0xC1:BC=Pop();break;case 0xD1:DE=Pop();break;case 0xE1:HL=Pop();break;case 0xF1:v=Pop();A=v>>8;F=v&255;break;
   case 0xEB:v=DE;DE=HL;HL=v;break;
   case 0xED:v=Byte();if(v==0x73){n=Word();M[n]=(byte)SP;M[n+1]=(byte)(SP>>8);}else if(v==0x53){n=Word();M[n]=(byte)E;M[n+1]=(byte)D;}else if(v==0x5B){n=Word();DE=M[n]+256*M[n+1];}else if(v==0xA0){M[DE]=M[HL];DE=(DE+1)&65535;HL=(HL+1)&65535;BC=(BC-1)&65535;}else if(v==0x52){n=HL-DE-(F&1);HL=n&65535;F=(HL==0?64:0)|(n<0?1:0);}else if(v==0xB0){int count=BC==0?65536:BC;for(int i=0;i<count;i++){M[DE]=M[HL];DE=(DE+1)&65535;HL=(HL+1)&65535;}BC=0;}else throw new Exception("ED "+v);break;
   case 0xDD:v=Byte();if(v==0x77){M[IX+(sbyte)Byte()]=(byte)A;}else if(v==0xE5){Push(IX);}else if(v==0xE1){IX=Pop();}else if(v==0x26){IX=(IX&255)|(Byte()<<8);}else if(v==0x36){n=IX+(sbyte)Byte();M[n]=(byte)Byte();}else if(v==0x34||v==0x35){n=IX+(sbyte)Byte();M[n]=(byte)(M[n]+(v==0x34?1:-1));Flag(M[n]);}else if(v==0xBC){n=IX>>8;F=(A==n?64:0)|(A<n?1:0);}else if((v&0xC7)==0x46)Set((v>>3)&7,M[IX+(sbyte)Byte()]);else if(v==0xCB){n=(sbyte)Byte();v=Byte();int bit=(v>>3)&7,addr=IX+n;if(v>=0xC0)M[addr]|=(byte)(1<<bit);else if(v>=0x80)M[addr]&=(byte)~(1<<bit);else F=(F&1)|((M[addr]&(1<<bit))==0?64:0);}else throw new Exception("DD "+v);break;
   case 0xFB:case 0xF3:break;case 0x76:Idle++;break;
   default:throw new Exception("Opcode "+op.ToString("X2")+" at "+(PC-1).ToString("X4"));
  }
 }}
 public void QueueText(string text){Enqueue(text);}
 public void SetHL(int v){HL=v;}
 public bool Zero(){return Z;} public bool Carry(){return (F&1)!=0;} public int EndHL(){return HL;} public int EndDE(){return DE;} public int EndBC(){return BC;} public void SetDE(int v){DE=v;} public void SetBC(int v){BC=v;} public void QueueIdle(int n){while(n-->0)Q.Enqueue(-1);}
}
"@
$bin=[IO.File]::ReadAllBytes((Join-Path $root 'wifi_setup_next18.bin'))
function Assert($condition,$message){if(-not $condition){throw $message}}
$count=0
foreach($scenario in @('success','wrong','reject','error','timeout','commitfail')){
 foreach($auto in @('0','1')){
  foreach($currentOnly in @(0,2)){
   $cpu=[ApCpu]::new($bin,$symbols);$cpu.Scenario=$scenario;$cpu.Auto=$auto
   $cpu.M[$symbols['flag1']+3]=$currentOnly
   $cpu.Put(0x7000,('newap'+[char]1+'-42'));$cpu.M[$symbols['AP_item']]=0;$cpu.M[$symbols['AP_item']+1]=0x70
   for($i=0;$i -lt 63;$i++){$cpu.M[$symbols['INPBUFF']+$i]=32}
   $cpu.Put($symbols['INPBUFF'],'secret');$cpu.M[$symbols['INPBUFF']+6]=32; $cpu.M[$symbols['INLEN']]=6
   $cpu.Run('ep11')
   Assert ($cpu.Commands[0] -eq 'AT+CWJAP_CUR="newap","secret"') 'Malformed trial command'
   $success=$scenario -eq 'success' -or ($scenario -eq 'commitfail' -and $currentOnly -eq 2)
   Assert ($cpu.Auto -eq $auto) 'Auto AP not restored'
   Assert ($cpu.Commands.Contains('AT+RST') -eq (-not $success)) 'Wrong fallback branch'
   $saved=@($cpu.Commands | Where-Object {$_ -like 'AT+CWJAP_DEF=*'})
   Assert ($saved.Count -eq [int](($scenario -in @('success','commitfail')) -and $currentOnly -eq 0)) 'Saved failed trial or changed current-only default'
   if($saved.Count){Assert ($saved[0] -eq 'AT+CWJAP_DEF="newap","secret"') 'Malformed save command'}
   Assert ($cpu.Messages.Contains('ON ') -eq (-not $success)) 'Incorrect recovery result'
   Assert ($cpu.SP -eq 0x67FE) 'Stack imbalance before menu exit'
   if($scenario -eq 'wrong'){Assert ($cpu.Messages.Contains('..wrong password')) 'Wrong password reason lost'}
   if($scenario -eq 'reject'){Assert ($cpu.Messages.Contains('..connection failed')) 'Connection failure reason lost'}
   $count++
  }
 }
}
foreach($boot in @('offline','silent','earlyip')){
 foreach($auto in @('0','1')){
  $cpu=[ApCpu]::new($bin,$symbols);$cpu.Auto=$auto;$cpu.Boot=$boot
  $cpu.Run('ap_restore_default')
  Assert ($cpu.Auto -eq $auto) 'Auto AP cleanup failure'
  Assert ($cpu.Zero() -eq ($boot -eq 'earlyip')) 'Incorrect restart outcome'
  Assert ($cpu.SP -eq 0x6800) 'Recovery stack imbalance'
  $count++
 }
}
foreach($text in @("`r`nWIFI CONNECTED`r`nOK`r`n","`r`nFAIL`r`n","`r`nERROR`r`n",('x'*5000),('x'*200+"`r`nOK`r`n"),"`r`nNOT OK`r`n")){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['ok_']);$cpu.QueueText($text)
 $cpu.M[$symbols['TX_buf']]=165
 $cpu.Run('ap_wait_line')
 Assert ($cpu.Zero() -eq ($text.EndsWith("`r`nOK`r`n"))) 'Response parsing failure'
 Assert ($cpu.M[$symbols['TX_buf']] -eq 165) 'RX buffer overflow'
 Assert ($cpu.SP -eq 0x6800) 'Wait stack imbalance'
 $count++
}
foreach($password in @('',('a'*63))){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Scenario='success'
 $cpu.Put(0x7000,('newap'+[char]1+'-42'));$cpu.M[$symbols['AP_item']]=0;$cpu.M[$symbols['AP_item']+1]=0x70
 for($i=0;$i -lt 63;$i++){$cpu.M[$symbols['INPBUFF']+$i]=32}
 $cpu.M[$symbols['INLEN']]=$password.Length
 if($password.Length){$cpu.Put($symbols['INPBUFF'],$password)}
 $cpu.Run('ep11')
 Assert ($cpu.Commands[0] -eq ('AT+CWJAP_CUR="newap","'+$password+'"')) 'Password boundary trial failure'
 Assert ($cpu.Commands[1] -eq ('AT+CWJAP_DEF="newap","'+$password+'"')) 'Password boundary save failure'
 $count++
}
# New regression coverage runs real assembled helper/editor/parser instructions.
foreach($sample in @(@('a,b"c\d','a\,b\"c\\d'),@('tail  ','tail  '),@('',''))){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put(0x7000,$sample[0]);$cpu.SetHL(0x7000);$cpu.SetDE($symbols['TX_buf']);$cpu.SetBC($sample[0].Length)
 $cpu.Run('at_escape');$cpu.M[$cpu.EndDE()]=0
 Assert (-not $cpu.Carry()) 'Valid string rejected by encoder'
 Assert ($cpu.Str($symbols['TX_buf']) -eq $sample[1]) 'AT escaping mismatch'
 $count++
}
$cpu=[ApCpu]::new($bin,$symbols);$cpu.Put(0x7000,'"');$cpu.SetHL(0x7000);$cpu.SetDE($symbols['TX_buf']+207);$cpu.SetBC(1);$cpu.M[$symbols['TX_buf']+208]=165
$cpu.Run('at_escape');Assert ($cpu.Carry() -and $cpu.M[$symbols['TX_buf']+208] -eq 165) 'TX bound not enforced';$count++
foreach($pair in @(@('prefix "a\,b\"c\\d",99','a,b"c\d'),@('"",99',''),@(('"'+('x'*32)+'",99'),('x'*32)))){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put(0x7000,$pair[0]);$cpu.SetHL(0x7000);$cpu.SetDE(0x7200);$cpu.SetBC($pair[0].Length)
 $cpu.Run('at_quoted');Assert (-not $cpu.Carry()) 'Quoted field rejected';Assert ($cpu.Str(0x7200) -eq $pair[1]) ('SSID unescape mismatch: raw=['+$pair[0]+'] expected=['+$pair[1]+'] actual=['+$cpu.Str(0x7200)+']');$count++
}
foreach($text in @('"unterminated','"bad\','no quotes','"bad'+[char]1+'field"')){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put(0x7000,$text);$cpu.SetHL(0x7000);$cpu.SetDE(0x7200);$cpu.SetBC($text.Length);$cpu.M[0x7280]=165
 $cpu.Run('at_quoted');Assert ($cpu.Carry()) 'Malformed quoted field accepted';Assert ($cpu.M[0x7280] -eq 165) 'Quoted copy escaped destination';$count++
}
foreach($length in @(0,1,3,8)){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['RX_buf']);$cpu.SetDE(5);$cpu.SetBC(8)
 for($i=0;$i -le 8;$i++){$cpu.M[$symbols['RX_buf']+$i]=165}
 $cpu.QueueText('a'*$length);$cpu.Run('receive_data1')
 Assert ($cpu.EndHL() -eq $symbols['RX_buf']+$length) 'Receiver lost actual end pointer'
 Assert ($cpu.EndBC() -eq 8-$length) 'Receiver lost remaining length'
 for($i=$length;$i -lt 8;$i++){Assert ($cpu.M[$symbols['RX_buf']+$i] -eq 0) 'Stale RX data survived'}
 Assert ($cpu.M[$symbols['RX_buf']+8] -eq 165) 'Receiver wrote past capacity';$count++
}
$cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['RX_buf']);$cpu.SetDE(3);$cpu.SetBC(4)
foreach($ch in @('a','b','c','d')){$cpu.QueueIdle(2);$cpu.QueueText($ch)}
$cpu.Run('receive_data1');Assert ($cpu.EndBC() -eq 0 -and $cpu.Str($symbols['RX_buf']).StartsWith('abcd')) 'Inter-byte timeout was not reset';$count++
$cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL(0x7000);$cpu.SetDE($symbols['ok']);$cpu.SetBC(0);$cpu.Run('look_for_string');Assert (-not $cpu.Zero()) 'Empty search scanned memory';$count++
foreach($name in @('a,b"c\d',('q'*32),'')){
 $password=' p,a"s\s  '
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put(0x7000,($name+[char]1+'-42'));$cpu.M[$symbols['AP_item']]=0;$cpu.M[$symbols['AP_item']+1]=0x70
 $cpu.Put($symbols['INPBUFF'],$password);$cpu.M[$symbols['INLEN']]=$password.Length
 $cpu.Run('ep11')
 $escapedName=$name.Replace('\','\\').Replace('"','\"').Replace(',','\,');$escapedPassword=$password.Replace('\','\\').Replace('"','\"').Replace(',','\,')
 Assert ($cpu.Commands[0] -eq ('AT+CWJAP_CUR="'+$escapedName+'","'+$escapedPassword+'"')) 'Full command escaping or trailing spaces failed';$count++
}
# The packed scan list keeps literal commas distinct from the internal separator.
$raw="`r`n+CWLAP:(`"a\,b\`"c\\d`",-42)`r`n+CWLAP:(`"plain`",-70)`r`n`r`nOK`r`n"
$cpu=[ApCpu]::new($bin,$symbols);$base=$symbols['AP_list_start'];$cpu.M[$symbols['flag1']+1]=0;$cpu.Put($base,$raw);$cpu.M[$symbols['ap_scan_end']]=($base+$raw.Length)-band 255;$cpu.M[$symbols['ap_scan_end']+1]=($base+$raw.Length)-shr 8
$cpu.Run('sap1');Assert (-not $cpu.Failed) 'Valid AP list rejected';Assert ($cpu.M[$symbols['flag1']+1] -eq 2) ('AP list count wrong: '+$cpu.M[$symbols['flag1']+1]+'; first='+$cpu.Str($base)+'; raw='+$raw);Assert ($cpu.Str($base) -eq ('a,b"c\d'+[char]1+'-42')) 'AP normalization corrupt';$count++
foreach($text in @('"unterminated',"`r`nOK`r`n")){
 $cpu=[ApCpu]::new($bin,$symbols);$raw=if($text.StartsWith('"')){'+CWLAP:('+$text}else{$text};$cpu.M[$symbols['flag1']+1]=0;$cpu.Put($base,$raw);$cpu.M[$symbols['ap_scan_end']]=($base+$raw.Length)-band 255;$cpu.M[$symbols['ap_scan_end']+1]=($base+$raw.Length)-shr 8
 $cpu.Run('sap1');Assert ($cpu.Failed -eq $text.StartsWith('"')) 'Truncated/empty scan handled incorrectly';$count++
}
# Editor tests include spaces, insertion, deletion, cursor gaps and a full buffer.
$cpu=[ApCpu]::new($bin,$symbols);$cpu.IX=63*256;$cursor=$symbols['CURSOR']+1;$input=$symbols['INPBUFF']
for($i=0;$i -lt 63;$i++){$cpu.M[$input+$i]=32};$cpu.M[$input+63]=0;$cpu.M[$symbols['INLEN']]=0;$cpu.M[$cursor]=0;$cpu.M[$input+65]=165
foreach($ch in 'ab  '.ToCharArray()){$cpu.A=[int]$ch;$cpu.SetHL($cursor);$cpu.Run('IN6')}
Assert ($cpu.M[$symbols['INLEN']] -eq 4) 'Editor lost trailing spaces'
$cpu.M[$cursor]=1;$cpu.A=[int][char]'X';$cpu.SetHL($cursor);$cpu.Run('IN6');Assert ($cpu.M[$symbols['INLEN']] -eq 5) 'Insert length failed';Assert ($cpu.Str($input).StartsWith('aXb  ')) 'Insert content failed'
$cpu.SetHL($cursor);$cpu.Run('BCKSPACE');Assert ($cpu.M[$symbols['INLEN']] -eq 4) 'Backspace length failed';Assert ($cpu.Str($input).StartsWith('ab  ')) 'Backspace content failed'
$cpu.M[$cursor]=1;$cpu.SetHL($cursor);$cpu.Run('DELETE');Assert ($cpu.M[$symbols['INLEN']] -eq 3) 'Delete length failed';Assert ($cpu.Str($input).StartsWith('a  ')) 'Delete content failed'
$cpu.M[$cursor]=10;$cpu.A=[int][char]'Z';$cpu.SetHL($cursor);$cpu.Run('IN6');Assert ($cpu.M[$symbols['INLEN']] -eq 11) 'Cursor gap length failed'
for($i=0;$i -lt 63;$i++){$cpu.M[$input+$i]=[int][char]'q'};$cpu.M[$input+63]=0;$cpu.M[$symbols['INLEN']]=63;$cpu.M[$cursor]=0
$cpu.A=[int][char]'X';$cpu.SetHL($cursor);$cpu.Run('IN6');Assert ($cpu.M[$symbols['INLEN']] -eq 63 -and $cpu.M[$input+63] -eq 0) 'Full insert corrupted sentinel';Assert ($cpu.M[$input+65] -eq 165) 'Editor overflowed compact buffer';$count+=6
# Query wrappers preserve the requested search capacity while clearing stale tails.
$cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['RX_buf']);$cpu.SetDE(3);$cpu.SetBC(100);$cpu.Put($symbols['RX_buf']+50,"OK`r`n")
$cpu.QueueText('x');$cpu.Run('receive_query');Assert ($cpu.EndBC() -eq 100) 'Query lost search capacity';Assert ($cpu.M[$symbols['RX_buf']+50] -eq 0) 'Old OK survived query';$count++
# No bytes outside the promised source range may be searched.
foreach($capacity in @(0,1,2,3,4)){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put(0x7000,'abc');$cpu.Put(0x7200,'bc');$cpu.SetHL(0x7000);$cpu.SetDE(0x7200);$cpu.SetBC($capacity);$cpu.Run('look_for_string')
 Assert ($cpu.Zero() -eq ($capacity -ge 3)) 'Bounded search result wrong'
 if($capacity -ge 3){Assert ($cpu.EndBC() -eq $capacity-3) 'Matched bytes not deducted exactly'}
 $count++
}
foreach($prefix in @('+CIUPDATE:','+CIPUPDATE:')){
 foreach($stage in 1..4){
  $cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['e1']+4*($stage-1));$cpu.QueueText("`r`n"+$prefix+$stage+"`r`nOK`r`n");$cpu.Run('ap_wait_line');Assert ($cpu.Zero()) 'OTA stage missing'
  $cpu.SetHL($symbols['ok_']);$cpu.Run('ap_wait_line');Assert ($cpu.Zero()) 'OTA stage consumed final OK';$count++
 }
}
foreach($reply in @("ERROR`r`n",'E',"X`r`n",'')){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['e1']);$cpu.QueueText($reply);$cpu.Run('ap_wait_line');Assert (-not $cpu.Zero()) 'Invalid OTA progress accepted';$count++
}
foreach($name in @('station  ','host,"\name')){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['INPBUFF'],$name);$cpu.M[$symbols['INLEN']]=$name.Length;$cpu.Run('snn1')
 $escaped=$name.Replace('\','\\').Replace('"','\"').Replace(',','\,')
 Assert ($cpu.Commands[0] -eq ('AT+CWHOSTNAME="'+$escaped+'"')) 'Hostname encoding/length wrong';$count++
}
$cpu=[ApCpu]::new($bin,$symbols);$name='"'*32;$password='\'*63;$cpu.Put(0x7000,($name+[char]1+'-42'));$cpu.M[$symbols['AP_item']]=0;$cpu.M[$symbols['AP_item']+1]=0x70
$cpu.Put($symbols['INPBUFF'],$password);$cpu.M[$symbols['INLEN']]=63;$cpu.Run('ep11');Assert (-not $cpu.Failed) 'Maximum escaped credentials rejected';Assert ($cpu.Commands[0].Length -eq 208) 'Maximum escaped command length wrong';$count++
$cpu=[ApCpu]::new($bin,$symbols);$cpu.M[$symbols['flag1']]=$cpu.M[$symbols['flag1']] -bor 32;$cpu.Run('gs4');Assert (($cpu.M[$symbols['flag1']] -band 32) -eq 0) 'Unknown status retained old connection flag';$count++
foreach($reply in @("`r`nOK`r`n","`r`n+CWLAP:(`"a\,b`",-42)`r`nOK`r`n")){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.M[$symbols['flag1']+1]=0;$cpu.ScanReply=$reply;$cpu.Run('sap4');Assert (-not $cpu.Failed) 'Full AP scan failed';Assert ($cpu.M[$symbols['flag1']+1] -eq [int]$reply.Contains('CWLAP:')) 'Full scan returned wrong count';$count++
}
foreach($hostName in @('192.168.1.1','example.org',('a'*63))){
 foreach($latency in @('0','23','65535')){
  $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['INPBUFF'],$hostName);$cpu.M[$symbols['INLEN']]=$hostName.Length;$cpu.PingReply="`r`n+"+$latency+"`r`nOK`r`n";$cpu.Run('ping_host')
  Assert ($cpu.Commands.Count -eq 1 -and $cpu.Commands[0] -eq ('AT+PING="'+$hostName+'"')) 'PING command malformed'
  Assert ($cpu.Messages.Contains('+'+$latency) -and -not $cpu.Messages.Contains('Ping failed')) 'PING result wrong'
  Assert ($cpu.SP -eq 0x67FE) 'PING stack imbalance';$count++
 }
}
foreach($reply in @("ERROR`r`n","+23`r`nERROR`r`n","WIFI DISCONNECT`r`nERROR`r`n","+PING:TIMEOUT`r`nERROR`r`n","+23garbage`r`nOK`r`n","+-1`r`nOK`r`n",'')){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['INPBUFF'],'example.org');$cpu.M[$symbols['INLEN']]=11;$cpu.PingReply=$reply;$cpu.Run('ping_host')
 Assert ($cpu.Messages.Contains('Ping failed')) 'PING accepted failure or malformed reply';$count++
}
$cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['INPBUFF'],'example.org');$cpu.M[$symbols['INLEN']]=11;$cpu.PingReply="+IPD,4:data`r`n+32`r`nOK`r`n";$cpu.Run('ping_host');Assert ($cpu.Messages.Contains('+32')) 'PING confused incoming data with RTT';$count++
foreach($abort in @(0,4)){
 $cpu=[ApCpu]::new($bin,$symbols);$cpu.M[$symbols['INLEN']]=0;if($abort){$cpu.InputKey=$abort;$cpu.M[$symbols['INLEN']]=5};$cpu.Run('ping_host');Assert ($cpu.Commands.Count -eq 0) 'Cancelled/empty PING sent a command';$count++
}
# SNTP configuration may start with CR/LF, echo or asynchronous notifications.
$bound=-1;for($p=$symbols['activate_tz'];$p -lt $symbols['activate_tz']+64;$p++){if($bin[$p-0xC000] -eq 1 -and $bin[$p-0xC000+3] -eq 205 -and [BitConverter]::ToUInt16($bin,$p-0xC000+4) -eq $symbols['look_for_string']){$bound=[BitConverter]::ToUInt16($bin,$p-0xC000+1);break}}
Assert ($bound -eq 255) 'SNTP search must cover the bounded received response'
foreach($reply in @("`r`n+CIPSNTPCFG:1,1`r`nOK`r`n","AT+CIPSNTPCFG?`r`n`r`n+CIPSNTPCFG:1,2`r`nOK`r`n","WIFI GOT IP`r`n+CIPSNTPCFG:1,-1`r`nOK`r`n")){$cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['RX_buf'],$reply);$cpu.SetHL($symbols['RX_buf']);$cpu.SetDE($symbols['time_zone_act']);$cpu.SetBC($bound);$cpu.Run('look_for_string');Assert ($cpu.Zero()) 'SNTP active configuration missed';$count++}
$cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['RX_buf'],"`r`n+CIPSNTPCFG:1,1`r`nOK`r`n");$cpu.SetHL($symbols['RX_buf']);$cpu.SetDE($symbols['time_zone_act']);$cpu.SetBC(13);$cpu.Run('look_for_string');Assert (-not $cpu.Zero()) 'Original 13-byte SNTP bug not reproduced';$count++
$cpu=[ApCpu]::new($bin,$symbols);$cpu.Put($symbols['RX_buf'],"`r`n+CIPSNTPCFG:0,1`r`nOK`r`n");$cpu.SetHL($symbols['RX_buf']);$cpu.SetDE($symbols['time_zone_act']);$cpu.SetBC($bound);$cpu.Run('look_for_string');Assert (-not $cpu.Zero()) 'Inactive SNTP configuration accepted';$count++
# Fallback is bounded independently; a slow normal join keeps the full budget.
foreach($auto in @('0','1')){foreach($boot in @('offline','silent')){$cpu=[ApCpu]::new($bin,$symbols);$cpu.Auto=$auto;$cpu.Boot=$boot;$cpu.Run('ap_restore_default');Assert (-not $cpu.Zero() -and $cpu.Idle -le 499) 'Missing Default AP still waits the old 3000-frame budget';Assert ($cpu.Auto -eq $auto -and $cpu.SP -eq 0x6800) 'Fast failure lost Auto AP/stack';$count++}}
foreach($auto in @('0','1')){foreach($delay in @(0,100,350,600)){$cpu=[ApCpu]::new($bin,$symbols);$cpu.Auto=$auto;$cpu.Boot='delayed';$cpu.BootIdle=$delay;$cpu.Run('ap_restore_default');Assert ($cpu.Zero() -eq ($delay -lt 500)) 'Fallback delayed GOT IP result';Assert ($cpu.Auto -eq $auto -and $cpu.SP -eq 0x6800 -and $cpu.Idle -le 499) 'Fallback deadline/Auto AP cleanup';$count++}}
$cpu=[ApCpu]::new($bin,$symbols);$cpu.SetHL($symbols['ok_']);$cpu.QueueIdle(800);$cpu.QueueText("`r`nOK`r`n");$cpu.Run('ap_wait_line');Assert ($cpu.Zero() -and $cpu.Idle -eq 800) 'Normal command/join timeout was shortened';$count++
# The old post-key path (kl1) enters speed management and can raise error 28.
$cpu=[ApCpu]::new($bin,$symbols);$cpu.InjectError28=$true;$cpu.Run('kl1');Assert ($cpu.Failed -and $cpu.SpeedManagementCalls -eq 1) 'Error 28 path fixture';$count++
# Both successful and failed Default AP recovery restore the ORIGINAL UART rate.
foreach($speed in @(7,12,14)){foreach($auto in @('0','1')){foreach($boot in @('normal','offline','earlyip')){$cpu=[ApCpu]::new($bin,$symbols);$cpu.M[$symbols['flag1']+7]=$speed;$cpu.Auto=$auto;$cpu.Boot=$boot;$cpu.Run('ap_restore_default');Assert ($cpu.RestoredSpeed -eq $speed -and $cpu.M[$symbols['flag1']+7] -eq $speed) 'Original UART baud not restored';Assert ($cpu.Auto -eq $auto) 'UART restoration changed Auto AP';$count++}}}
# Confirming an AP result must return to the UI, not re-enter baud scanning.
foreach($outcome in @('wrong','reject','success')){$cpu=[ApCpu]::new($bin,$symbols);$cpu.Scenario=$outcome;$cpu.Boot='offline';$cpu.ContinuePrompt=$true;$cpu.InjectError28=$true;$cpu.M[$symbols['flag1']+3]=2;$cpu.Put(0x7000,('newap'+[char]1+'-42'));$cpu.M[$symbols['AP_item']]=0;$cpu.M[$symbols['AP_item']+1]=0x70;$cpu.Put($symbols['INPBUFF'],'secret');$cpu.M[$symbols['INLEN']]=6;$cpu.Run('ep11');Assert (-not $cpu.Failed -and $cpu.SpeedManagementCalls -eq 0 -and $cpu.AkeyCalls -eq 1 -and $cpu.PC -eq $symbols['kl2']) 'AP key confirmation reruns speed management';$count++}
"PASS: $count assembled Z80 scenarios (UART and UI mocked; no hardware test)."