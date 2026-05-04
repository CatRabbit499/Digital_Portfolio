using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace System.Collections
using namespace System.Text
using namespace System.IO
using namespace System

###########################
##                       ##
##   PSColor Cosmetics   ##
##                       ##
###########################

enum Shade {
	FG_Dark  =  30
	BG_Dark  =  40
	FG_Light =  90
	BG_Light = 100
}
enum Color {
	Black	= 0
	Red		= 1
	Green	= 2
	Yellow	= 3
	Blue	= 4
	Magenta	= 5
	Cyan	= 6
	White   = 7
}

enum Style {
	Reset         = 0
	Bold          = 1   
	Dim           = 2  
	Italic        = 3  
	Underline     = 4  
	Blink         = 5  
	Overline      = 53
	Blink_Rapid   = 6
	Reverse       = 7  
	Hidden        = 8  
	Strikethrough = 9  
	
}

function getColor{
	param (
		[Shade]$shade,
		[string]$code
	)
	$symbol = [string]$code[-1]
	# Write-Host $code -NoNewLine
	if($symbol -as [int] -in 0..7){
		return ("`e[{0}m" -f ($shade.Value__ + [color]$symbol) )
	}
	$ASCII = switch($code[-1]){
		{$_ -eq  'r'} { [Shade]::Reset         }
		{$_ -eq  'b'} { [Style]::Bold          }
		{$_ -eq  'i'} { [Style]::Italic        }
		{$_ -eq  'o'} { [Style]::Overline      }
		{$_ -eq  'u'} { [Style]::Underline     }
		{$_ -eq  's'} { [Style]::Strikethrough }
	}
	return ("`e[{0}m" -f $ASCII.Value__)
	# Write-Host " -> " -NoNewLine
}

function Write-Colored {
	param(
		$strings,
		[switch]$L,
		[switch]$NoNewLine
	)
	foreach ($txt in $strings) {
		$txt | Select-String -Pattern "&[\drbious]" -AllMatches | ForEach-Object {
			# Write-Host "Line: $($_.Line)"
			foreach ($match in $_.Matches) {
				if($PSBoundParameters.ContainsKey('L')){
					$parsed = getColor -code $match.Value -shade FG_Light
				}
				else{
					$parsed = getColor -code $match.Value -shade FG_Dark
				}
				# Write-Host "$($match.Value) -> $($parsed)"
				$txt = $txt.Replace($match.Value, $parsed)
			}
			if($PSBoundParameters.ContainsKey('NoNewLine')){
				Write-Host $txt -NoNewLine
			}
			else{				
				Write-Host $txt
			}
		}
	}
}

###########################
##                       ##
##   Global  Variables   ##
##                       ##
###########################

$readPos = 0;
$pos = [ref]$readPos

###########################
##                       ##
##   Utility Functions   ##
##                       ##
###########################

function Sanity-Check {
	param (
		[Parameter(mandatory="true")]
		$vars = $args[0],
		[Parameter()]
		[string]$P
	)
	foreach($a in -split $vars){
		$x = (Get-Variable $a)
		if($PSBoundParameters.ContainsKey('P')){
			Write-Host $P -NoNewLine
		}
		"$($x.Value.GetTypeCode()) $($x.Name) = $($x.Value)"
	}
}

function Pretty-Print {
	param (
		[string]$text,
		[int]$interval
	)
	Write-Host "[Process]::Pretty-Print($($interval))" -ForegroundColor DarkGray
	$chars = $text.toCharArray();
	for ($i = $interval - 1; $i -lt $chars.Length; $i += $interval) {
		$chars[$i] = "`n"
	}
	return (-join $chars)
}   

function Read-Next {
    param (
        [int]$offset = $readPos,
		[int]$count
    )
	# Write-Host "[Process]::Read-Next( Offset: $($offset), Count: $($count) )" -ForegroundColor DarkGray
	$pos.Value += $count
	# Write-Colored "&1Position:&r &3$($offset) -> $($offset + $count)"
	return [Byte[]]($bytes[$offset..($count+$offset-1)])
}

function Check-Signature{
	Write-Host "[Process]::Check-Signature()" -ForegroundColor DarkGray
	$identifier = ([Byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
	$signature = ([System.BitConverter]::ToString($identifier))
	Write-Colored "&6Real:&r $($identifier) | $($signature)"

	$header = ([Byte[]](Read-Next -count 8))
	$integrity = ([System.BitConverter]::ToString($header))
	Write-Colored "&6Test:&r $($header) | $($integrity)"

	if($integrity -eq $signature){
		Write-Colored "&2Valid PNG File"
	}
	else{
		Write-Error "&1Invalid PNG File"
		Exit-PSHostProcess
	}	
}
# Write-Host "&3 -> $(getColor -code "&3")"
# Write-Colored "This text is &1RED&r, and this text is &2GREEN&r"
# Write-Colored "&6----------"

function Format-Binary {
	param(
		$input,
		[int]$len = 8,
		[int]$pad = 0
	)
	$out = @()
	foreach ($item in $input) {
        $out += , [System.Convert]::ToString($item,2).PadLeft($len, '0').PadLeft($pad)
    }
	return $out
}
# Write-Host (120 | Format-Binary)
$BaseValues = @{
	"257"= (0,  3)
	"258"= (0,  4)
	"259"= (0,  5)
	"260"= (0,  6)
	"261"= (0,  7)
	"262"= (0,  8)
	"263"= (0,  9)
	"264"= (0, 10)
	"265"= (1, 11)
	"266"= (1, 13)
	"267"= (1, 15)
	"268"= (1, 17)
	"269"= (2, 19)
	"270"= (2, 23)
	"271"= (2, 27)
	"272"= (2, 31)
	"273"= (3, 35)
	"274"= (3, 43)
	"275"= (3, 51)
	"276"= (3, 59)
	"277"= (4, 67)
	"278"= (4, 83)
	"279"= (4, 99)
	"280"= (4,115)
	"281"= (5,131)
	"282"= (5,163)
	"283"= (5,195)
	"284"= (5,227)
	"285"= (0,258)
	"00"=( 0,    1)
	"01"=( 0,    2)
	"02"=( 0,    3)
	"03"=( 0,    4)
	"04"=( 1,    5)
	"05"=( 1,    7)
	"06"=( 2,    9)
	"07"=( 2,   13)
	"08"=( 3,   17)
	"09"=( 3,   25)
	"10"=( 4,   33)
	"11"=( 4,   49)
	"12"=( 5,   65)
	"13"=( 5,   97)
	"14"=( 6,  129)
	"15"=( 6,  193)
	"16"=( 7,  257)
	"17"=( 7,  385)
	"18"=( 8,  513)
	"19"=( 8,  769)
	"20"=( 9, 1025)
	"21"=( 9, 1537)
	"22"=(10, 2049)
	"23"=(10, 3073)
	"24"=(11, 4097)
	"25"=(11, 6145)
	"26"=(12, 8193)
	"27"=(12,12289)
	"28"=(13,16385)
	"29"=(13,24577)
}

$CodeTable = [Dictionary[string,pscustomobject]]@{}

foreach($entry in $BaseValues.GetEnumerator()){
  #Write-Host "$($entry.Key)= $($entry.Value)"
  $CodeTable[$entry.Key] = [pscustomobject]@{
    Extra= $entry.Value[0]
    Value= $entry.Value[1]
  }
}

function Get-Table_Entries {
	[CmdletBinding()]
	param(
		[int[]]$alphabet,
		[int[]]$codeList
	)
	if($PSBoundParameters.Verbose){
		Write-Host (
			"[Process]::Get-Table_Entries(`n  {0} `$alphabet[{1}],`n  {2} `$codeList[{3}]`n)" -f 
			$alphabet.GetType().Name,
			$alphabet.Length,
			$codeList.GetType().Name,
			$codeList.Length
		)		
	}
	$code_lengths = @()
	for($x=0; $x -le $alphabet.Count-1; $x++){
	  $code_lengths += , [ValueTuple[int,int]]::new($alphabet[$x],$codeList[$x])
	}
	$sorted = $code_lengths | Sort-Object -Property Item2
	$sorted
}

function Get-Bit_Values {
	[CmdletBinding()]
	param(
		[ValueTuple[int,int][]]$entries,
		[ref]$target
	)
	if($PSBoundParameters.Verbose){
		Write-Host (
			"[Process]::Get-Bit_Values( {0} `$entries[{1}] )" -f 
				$entries.GetType().Name,
				$entries.Count
		)
	}
	foreach($entry in $entries){
	  $cond = $target.Value | Get-Member -Name $entry.Item2
	  if($cond -eq $null){
		$target.Value | Add-Member -MemberType NoteProperty -Name $entry.Item2 -Value @($entry.Item1)
	  }
	  else{
		$target.Value.($cond.Name) += , $entry.Item1
	  }
	}
	$bv = [int[]]($target.Value | Get-Member -MemberType Properties | ForEach-Object { ($_.Name) })
	$bv.ForEach({ $target.Value.$_ = @($target.Value.$_ | Sort-Object)})
	# $target.Value
	$bv
}

function Get-BL_Count {
	# """
	# 1.  Let bl_count[N] be the number of codes of length N, N >= 1.
	# """
	[CmdletBinding()]
	param(
		[int[]]$bv,
		[ref]$target
	)
	if($PSBoundParameters.Verbose){
		Write-Host "[Process]::Get-BL_Count( $($bv.GetType()) { $($bv -join ' ') } )"
	}
	# Write-Host "MAX_BITS: $MAX_BITS"
	$bit_length_count = New-Object int[] ($MAX_BITS+1)
	
	for($x=1; $x -le $Stats.Maximum; $x++){
		if($bv.Contains($x)){
			$bit_length_count[$x] = $target.Value.$x.Count
			$msg = "`$bit_length_count[$x] = $($bit_length_count[$x])"
		}
		else{
			$msg = "Skipping Code Length $x"
		}
		if($PSBoundParameters.Verbose){
			Write-Host $msg
		}
	}
	$bit_length_count
	# Write-Host
}

function Get-Code_Bases {
	# """
	# 2.  	code = 0;
	#		bl_count[0] = 0;
	#		for (bits = 1; bits <= MAX_BITS; bits++) {
	#			code = (code + bl_count[bits-1]) << 1;
	#			next_code[bits] = code;
	#		}
	# """
	[CmdletBinding()]
	param(
		[int[]]$bit_lc
	)
	if($PSBoundParameters.Verbose){
		Write-Host (
			"[Process]::Get-Code_bases( {0} { $bit_lc } )" -f $bit_lc.GetType()
		)
	}
	$code = 0
	$bit_lc[0] = 0
	$bit_length_bases = New-Object int[] ($MAX_BITS+1)
	for($bits=1; $bits -le $MAX_BITS; $bits++){
		$code = ($code + $bit_lc[$bits-1]) -shl 1
		if($PSBoundParameters.Verbose){
			Write-Host "[$bits-bits] $code = $($code | Format-Binary -len $bits)"
		}
		$bit_length_bases[$bits] = $code
		# "`$code_bases = $code_bases"
	}
	$bit_length_bases
	# Write-Host
}

function Get-Bit_Codes {
	# """
	# 3.	for (n = 0;  n <= max_code; n++) {
	#			len = tree[n].Len;
	#			if (len != 0) {
	# 				tree[n].Code = next_code[len];
	#				next_code[len]++;
	#			}
	#		}
	# """
	[CmdletBinding()]
	param(
		[int[]]$cb,
		[int[]]$bv,
		[ref]$target
	)
	if($PSBoundParameters.Verbose){
		Write-Host (
			"[Process]::Get-Bit_Codes(`n  {0} {1}`n  {2} {3}`n  {4} {5}`n)" -f 
			$cb.GetType().Name,($cb -join ' '),
			$bv.GetType().Name,($bv -join ' '),
			$target.Value.GetType().Name,
			$target.Value
		)		
	}
	foreach($x in $bv){
		if($x -eq 0){ # Ignore unused codes
			continue
		}
		# Write-Host "$x-bits: $($target.Value.$x)"
		for($t=0; $t -lt ($target.Value.$x).Count; $t++){
			$code = ($t + $cb[$x]) 
			$codeString = ($code | Format-Binary -len $x)
			$bit_codes += , [ValueTuple[int,string,int]]::new(
				$target.Value.$x[$t],
				$codeString,
				$code
			)
		}
	}
	$bit_codes
	# Write-Host
}

function Display-Bit_Codes {
	[CmdletBinding()]
	param(
		[ValueTuple[int,string,int][]]$data_in,
		[string]$title = "Len"
	)
	$sorted = $data_in | Sort-Object -Property Item3
	$stats = $sorted | Measure-Object -Property Item1,Item2,Item3 -Maximum
	$W1 = $stats[0].Maximum.ToString().Length
	$W2 = $stats[1].Maximum.ToString().Length
	$W3 = $stats[2].Maximum.ToString().Length
	Write-Host ("{0,-$W1} {1,-$W2} {2,-$W3}" -f $title,'Bin','Dec' )
	Write-Host ("{0} {1} {2}" -f ('-'*$W1),('-'*$W2),('-'*$W3) )
	$sorted.ForEach({
		Write-Host ("{0,$W1} {1,-$W2} {2,$W3} " -f $_.Item1,$_.Item2,$_.Item3)
	})
}
						
enum BType {
	None     = 00
	Fixed    = 01
	Dynamic  = 10
	Reserved = 11
}

$IMAGE_WIDTH = $null
$IMAGE_LINES = $null
$TOKEN_LIST = [Array]@()
function Read-Block {
	[CmdletBinding()]
	param()
	###########################
	##                       ##
	##  Get next Block Size  ##
	##                       ##
	###########################

	$BlockSize = [byte[]](Read-Next -count 4)
	$hex = [BitConverter]::ToString($BlockSize)
	# Write-Host "BlockSize: $($BlockSize) | $($hex) = " -NoNewLine
	[Array]::Reverse($BlockSize)
	$BlockSize = [BitConverter]::ToInt32($BlockSize)
	# Write-Host $BlockSize

	###########################
	##                       ##
	##    Read Next Block    ##
	##                       ##
	###########################

	$ChunkType = -join [Char[]](Read-Next -count 4)
	# Write-Host $ChunkType

	$Block = [byte[]](Read-Next -count ($BlockSize))
	$hex = [System.BitConverter]::ToString($Block)
	# Write-Host "Block: $($Block) | $($hex)"
	
	Write-Colored -L "&2BLK&r: &0$ChunkType ($BlockSize)"

	enum ChunkPriority {
		IHDR= 0
		iCCP= 1
		sRGB= 1
		gAMA= 1
		cHRM= 1
		sBIT= 1
		PLTE= 2
		tRNS= 3
		bKGD= 3
		pHYs= 3
		sPLT= 3
		hIST= 3
		IDAT= 4
		IEND= 5
		tIME= 0
		tEXt= 0
		zTXt= 0
		iTXt= 0
	}

	$ChunkFormat = @{
		"IHDR"= @(4,4,1,1,1,1,1)
		"pHYs"= @(4,4,1)
		"sRGB"= @(1)
		"IEND"= @(0)
		"IDAT"= "ZLIB"
		"eXIf"= "TIFF"
		"tEXt"= "ASCII"
	}
	
	$fmt = $ChunkFormat[$ChunkType]
	$out = @()
	$outRef = [ref]$out
	$print = ""
	$printRef = [ref]$print
	
	switch($ChunkType){
		{$ChunkFormat[$_] -eq "ASCII"}{
			$keyword = $Block.IndexOf([byte]0x00)
			$content = $BlockSize - $keyword - 1
			$fmt = @($keyword,1,$content)
		}
		{$ChunkFormat[$_] -eq "TIFF"}{
			$Block | Format-Hex
			
			[File]::WriteAllBytes("./EXIF.bin",$Block)
			
			$ByteOrder = $Block[0..3]
			$LE = $null
			# 0..1 | foreach { $ByteOrder[$_] = [string]$ByteOrder[$_] }
			$Ascii = ($ByteOrder | Format-Hex).Ascii
			switch($Ascii){
				{$_ -eq "II* "} { $LE = [bool]1; "Little Endian (Intel)" }
				{$_ -eq "MM *"} { $LE = [bool]0; "Big Endian (Motorola)" }
				default {
					Write-Error "Invalid Header: '$Ascii'"
				}
			}
			$IFD0 = [Int32]::Parse(-join $Block[$LE ? 7..4 : 4..7])
			Write-Host "IFD0: $IFD0"
			
			function Read-IFD{
				param(
					[int]$offset
				)
				$ifd = $Block[$IFD0..($IFD0+11)]
				$tag     = "0x"+-join $ifd[$LE ?  1..0 : 0.. 1] -as [long]
				$type    = "0x"+-join $ifd[$LE ?  3..2 : 2.. 3] -as [long]
				$count   = "0x"+-join $ifd[$LE ?  7..4 : 4.. 7] -as [long]
				$vOffset = "0x"+-join $ifd[$LE ? 11..8 : 8..11] -as [long]
				
				@(
					$tag,
					$type,
					$count,
					$vOffset
				)
			}
			$ifd = Read-IFD $IFD0
			$ifd
			Write-Colored((
				"&6Tag:     &r{0,5}`n"+
				"&6Type:    &r{1,5}`n"+
				"&6Count:   &r{2,5}`n"+
				"&6vOffset: &r{3,5}`n") -f $ifd
			)
			# Pause
		}
		{$ChunkFormat[$_] -eq "ZLIB" }{
			$CMF = $Block[0]
			$CM = $Block[0] -band 0xF
			$CINFO = $Block[0] -shr 4
			Write-Colored ((
				"&1ZLIB CMF&r: {0,8:B8}`n"+
				"  &3Method&r: {1,1:D} | {1,4:B4}`n"+
				"  &3CMInfo&r: {2,1:D} | {2,4:B4}`n") -f $CMF,$CM,$CINFO
			)
			$FLG = $Block[1]
			$FCHECK = ($Block[1] -band 0x1F)        # Bit 0-4
			$FDICT  = ($Block[1] -band 0x20) -shr 5 # Bit 5
			$FLEVEL = ($Block[1] -band 0xC0) -shr 6 # Bit 6-7
			Write-Colored ((
				"&1ZLIB FLG&r: {0,3:B}`n"+
				"  &3FCHK&r: {1,2:D} | {1,5:B5}`n"+
				"  &3DICT&r: {2,2:D} | {2,5:B1}`n"+
				"  &3FLVL&r: {3,2:D} | {3,5:B2}`n") -f $FLG,$FCHECK,$FDICT,$FLEVEL
			)
			
			$SUM = ($CMF | Format-Binary) + ($FLG | Format-Binary)
			$val = [Convert]::ToUInt16($SUM,2)
			Write-Colored "&1CheckSum (CMF*2^8 + FLG)&r: $($SUM) | $($val)"
			Write-Host "Checking Modularity (31)..."
			Write-Colored  "$(($val % 31 -eq 0) ? '&2Valid Format!' : '&1Invalid Format!')"
			
			$Block[0..1] | Format-Binary
			$deflate = $Block[2..$Block.Length] | ForEach-Object { $tmp = $_ | Format-Binary; -join $tmp[$tmp.Length..0] }
			
			$defStr = -join $deflate
			# Write-Colored "&1Deflate&r: " -NoNewLine
			Write-Colored (
				"&0{0}...{1}" -f 
					$defStr.Substring(0,32),
					$defStr.Substring($defStr.Length-32)
			) -L
			
			# Pause
			$tokens_ref = [ref]$TOKEN_LIST
			
			$test = $deflate.ToCharArray()
			if($CurrentBlock.Item2){
				$test = ($CurrentBlock.Item3 + $test)
				Write-Host ((-join $test[0..100])+"...")
				Pause
			}
			$bitstream_ref = [ref]$test
			
			-join $test >> ("{0:yyyy-MM-dd}.bit" -f [datetime]::Now)
			
			$BlockNumber = 0
			$blockRef = [ref]$BlockNumber
			$TokenNumber = 0
			function Read-ZLIB_Block {
				[CmdletBinding()]
				param($test)
				
				$token_list = [Array]@()
				$tList = [ref]$token_list
				
				$header = $test[0..2]
				Write-Colored "&1Header&r: " -NoNewLine
				Write-Colored "&3$(-join $header)&r &1->&r &0$($header[0])&r &7$(-join $header[2..1])&r" -L
				$bFinal = $header[0]
				$tList.Value += , ($bFinal -eq '1' ? 'last' : '!')
				Write-Colored "  &3bFinal&r: $($bFinal -eq '1')"
				
				
				$bType = -join $header[2..1]
				Write-Colored "  &3bType&r: " -NoNewLine
				$type = switch($bType -as [BType]){
					None { "Uncompressed" }
					Fixed { "Fixed Huffman"; $tList.Value += , "fixed"}
					Dynamic { "Dynamic Huffman"; $tList.Value += , "dynamic" }
					Reserved { "Reserved (error)" }
				}
				Write-Host $type					
			
				# $tList 
				switch($BType -as [Btype]){
					Dynamic {
						$HLIT  = "0b"+-join $test[ 7.. 3];
						$HDIST = "0b"+-join $test[12.. 8];
						$HCLEN = "0b"+-join $test[16..13]; # Huffman Code bits (3x+12) 
						$lit = [byte]$HLIT  + 257
						$dst = [byte]$HDIST + 1
						$len = [byte]$HCLEN + 4
						if($PSBoundParameters.Verbose){
							Write-Colored ((
								"&1HLIT&r:  &3{0} ({3} + 257)`n"+
								"&1HDIST&r: &3{1} ({4} + 1)  `n"+
								"&1HCLEN&r: &3{2} ({5} + 4)  `n") -f $lit,$dst,$len,$HLIT,$HDIST,$HCLEN
							)						
						}
														
						$freqOrder = [int[]]@(16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15)
						
						$codes = [int[]]@()
						$hc_bits = ($len)*3
						for($x=17; $x -lt (17+$hc_bits); $x+=3){
							$code = "0b"+-join $test[$($x+2)..($x)] -as [byte];
							$codes += , $code
						}
						if($PSBoundParameters.Verbose){							
							Write-Host "Code Bit-Len:"
						}
						for($x=0; $x -lt $codes.Length; $x++){
							$codeFor = "{0,2}" -f $freqOrder[$x]
							if($PSBoundParameters.Verbose){
								Write-Host ("{0} | {1} ({1:B3})" -f $codeFor,$codes[$x])
							}
						}
						
						$Table_Entries = (Get-Table_Entries $freqOrder $codes)
						
						$lenDict = [pscustomobject]@{}
						$lenDict_ref = [ref]$lenDict
						$Bit_Values = (Get-Bit_Values $Table_Entries $lenDict_ref)
						$stats = ($Bit_Values | Measure-Object -Maximum)
						$MAX_BITS = $stats.Maximum
						# $lenDict
						
						$BL_Count = (Get-BL_Count $Bit_Values $lenDict_ref)
						
						$Code_Bases = (Get-Code_Bases $BL_Count)
						
						# for($k=0; $k -lt $Code_Bases.Count; $k++){
							# Write-Host "[Base_$k]",$Code_Bases[$k]
						# }
						# Write-Host

						$CodeBits = (Get-Bit_Codes $Code_Bases $Bit_Values $lenDict_ref)
						
						# $CodeBits
						
						if($PSBoundParameters.Verbose){
							$CodeBits.ForEach({
								switch($_){
									{$_.Item1 -in  0..15} { $prefix = "lens  " }
									{$_.Item1 -eq     16} { $prefix = "repeat" }
									{$_.Item1 -in 17..18} { $prefix = "zeros " }
								}
								Write-Host (
									"$prefix {0,2} ! {1,-5} {2,2} " -f 
										$_.Item1,
										$_.Item2,
										$_.Item3
								)
							})
						}
						# Pause
						
						$len_start = 17 + $hc_bits
						$tokens_processed = 0
						Write-Colored ("&1Count&r: &3{0,3} {1,2} {2,2}" -f $lit,$dst,$len)
						$ct = 0
						$max_tokens = $lit + $dst
						if($PSBoundParameters.Verbose){
							Write-Host "MAX_BITS: $MAX_BITS"
							Write-Host "Tokens To Process: $max_tokens"							
						}
						for($x=$len_start; $tokens_processed -lt $max_tokens; $x+=$MAX_BITS){
							$percent = ($tokens_processed / $max_tokens) * 100
							Write-Progress -Activity "Processing Items" `
										   -Status "Item $x of $totalItems" `
										   -PercentComplete $percent `
										   -CurrentOperation "Processing item $i"
							$token = -join $test[$x..($x+$MAX_BITS-1)]
							
							$CodeBits | where { $token.StartsWith($_.Item1) }
							$match = ($CodeBits | where { $token.StartsWith($_.Item2) })
							$token_value = $match.Item1
							$token_bits = $match.Item2
							$token_lit = $match.Item3
							$token_len = $x+$token_bits.Length
							# Write-Host "Matched $token_bits"
							$x -= ($MAX_BITS - $token_bits.Length)
							switch($token_value){
								{$_ -in  0..15} { $word = "lens   "; $data = $token_value; $count=1}
								{$_ -eq     16} { $word = "repeat "; $data = $([int]("0b"+-join $test[($token_len+1)..($token_len)]) +  3); $x+=2; $count=$data}
								{$_ -eq     17} { $word = "zeros  "; $data = $([int]("0b"+-join $test[($token_len+2)..($token_len)]) +  3); $x+=3; $count=$data}
								{$_ -eq     18} { $word = "zeros  "; $data = $([int]("0b"+-join $test[($token_len+6)..($token_len)]) + 11); $x+=7; $count=$data}
							}
							$output = "$word $data"
							$tList.Value += , $output
							$tokens_processed += $count
							$len_start = $x+$MAX_BITS # Save Data Start offset
							$ct++
							if($PSBoundParameters.Verbose){
								# Write-Host "NumTokens: $tokens_processed"
								Write-Host ("{0,3:D}] $output ($($count)x)" -f $tokens_processed)								
							}
						}
						Write-Progress -Activity "Processing Items" -Complete
						$TokenStats = New-Object int[] ($lit+$dst)
						if($PSBoundParameters.Verbose){
							Write-Host "Processed $ct ($tokens_processed) tokens!"
							Write-Host "TokenStats_len:",$TokenStats.Length							
						}
			
						$x = 0
						$tp = -2
						$last_token = $null
						$msg = "Token Table"							
						foreach($stat in $tList.Value){
							$parts = -split $stat
							switch($parts[0]){
								"lens" { $msg += "`n$stat";
									$TokenStats[$x] = $parts[1]; $x++;
								}
								"repeat" {
									1..([int]$parts[1]) | ForEach({	$msg += "`n[Copy] lens $($TokenStats[$x-1])"; 
										$TokenStats[$x] = $TokenStats[$x-1]; $x++; })
								}
								"zeros" {
									1..([int]$parts[1]) | ForEach({ $msg += "`n[Copy] lens $($TokenStats[$x])"; $x++; })
								}
								default { $msg += "`nSkipping token $stat";	}
							}
							if($PSBoundParameters.Verbose){
								# Write-Host $msg
							}
							$last_token = $parts
							$tp++
						}

						$lit_stats = $TokenStats[0..($lit-1)]
						$dst_stats = $TokenStats[$lit..($lit+$dst)]
						
						if($PSBoundParameters.Verbose){
							# for($x=0; $x -lt $lit; $x++){
								# ("litlen {0,3} {1,2}" -f  $x,$TokenStats[$x])
							# }
							# for($x=$lit; $x -lt ($lit+$dst); $x++){
								# ("dist   {0,3} {1,2}" -f  ($x-$lit),$TokenStats[$x])
							# }
								
							# Pause
							$lit_stats | ForEach-Object -Begin {$i=0} -Process { ("litlen {0,3} {1,2}" -f $i,$_); $i++ }
							$dst_stats | ForEach-Object -Begin {$i=0} -Process { ("dist   {0,3} {1,2}" -f $i,$_); $i++ }
						}
						
						$Literal_Entries = (Get-Table_Entries (0..($lit_stats.Count-1)) $lit_stats)

						$litDict = [pscustomobject]@{}
						$litDict_ref = [ref]$litDict
						$LC_Bit_Values = (Get-Bit_Values $Literal_Entries $litDict_ref)
						# $LC_Bit_Values
						# $litDict
						
						$Stats = ($LC_Bit_Values | Measure-Object -Maximum)
						$LIT_MAX = $Stats.Maximum
						$MAX_BITS = $LIT_MAX
						$LC_BL_Count = (Get-BL_Count $LC_Bit_Values $litDict_ref)
						
						$LC_Code_Bases = (Get-Code_Bases $LC_BL_Count)
						
						# for($k=0; $k -lt $LC_Code_Bases.Count; $k++){
							# Write-Host "[Base_$k]",$LC_Code_Bases[$k]
						# }
						# Write-Host
						
						$Lit_Table = (Get-Bit_Codes $LC_Code_Bases $LC_Bit_Values $litDict_ref)
						# (Display-Bit_Codes $Lit_Table 'Lit')
						
						# Pause
						
						$Distance_Entries = (Get-Table_Entries (0..($dst_stats.Count-1)) $dst_stats)

						$dstDict = [pscustomobject]@{}
						$dstDict_ref = [ref]$dstDict
						$DC_Bit_Values = (Get-Bit_Values $Distance_Entries $dstDict_ref)
						# $DC_Bit_Values
						# $dstDict
						
						$Stats = ($DC_Bit_Values | Measure-Object -Maximum)
						$DST_MAX = $Stats.Maximum
						$MAX_BITS = $DST_MAX
						$DC_BL_Count = (Get-BL_Count $DC_Bit_Values $dstDict_ref)
						
						$DC_Code_Bases = (Get-Code_Bases $DC_BL_Count)
						
						# for($k=0; $k -lt $DC_Code_Bases.Count; $k++){
							# Write-Host "[Base_$k]",$DC_Code_Bases[$k]
						# }
						# Write-Host
						
						$Dst_Table = (Get-Bit_Codes $DC_Code_Bases $DC_Bit_Values $dstDict_ref)
						# (Display-Bit_Codes $Dst_Table 'DC')
						
						# Pause
						
						# $lenDict
						# $litDict
						# $dstDict
						# (Display-Bit_Codes $CodeBits 'Len')
						# (Display-Bit_Codes $Lit_Table 'Lit')
						# (Display-Bit_Codes $Dst_Table 'Dst')
						
						if($PSBoundParameters.Verbose){
							$CodeBits  | Sort-Object -Property Item1 | Format-Table
							$Lit_Table | Sort-Object -Property Item1 | Format-Table
							$Dst_Table | Sort-Object -Property Item1 | Format-Table
						}
						
						$Lit_Stats = ($Lit_Table | Measure-Object)
						
						# $freqOrder
						# Pause
						
					
						
						enum TokenType {
							Literal
							Length
							Distance
						}
						
						
						if($PSBoundParameters.Verbose){
							Write-Host "Start: $len_start"
						}
						for($x=$len_start; $x -lt $test.Length; $x+=$token_len){
							$PC = [Math]::Floor(($TokenNumber+1)/16384*100)
							Write-Progress -Activity "Processing Tokens" -Status "Item $TokenNumber of 16384" `
										   -PercentComplete $PC
							$token = -join $test[$x..($x+$LIT_MAX-1)]
							# Check Length Codes
							$match_lc = ($Lit_Table | where { $token.StartsWith($_.Item2) })
							$match_value = $match_lc.Item1
							$match_bits = $match_lc.Item2
							$match_lit = $match_lc.Item3
							$match_len = $match_bits.Length
							$token_len = $match_len
							
							$extra_bits = 0
							$offset = 0
							$huff = $null
							if($match_value -eq 256){
								if($PSBoundParameters.Verbose){
									Write-Colored -L ("&0Matched&r &3{0,3}&r &3(&0{1}&3)" -f $match_value,$match_bits)
									Write-Colored "&2---------"
									Write-Colored "&6[[EOS]]&r"
								}
								$tList.Value += , "end"
								$last_x = $x + $match_bits.Length
								$block_ref.Value = $false
								break
							}
							if($match_value -gt 256){
								$CodeBase = $CodeTable["$match_value"]
								$extra_bits = $CodeBase.Extra
								$value_base = $CodeBase.Value
								
								if($extra_bits -gt 0){
									$huff_start = $x+$token_len
									$huff = -join $test[($huff_start+$extra_bits-1)..$huff_start]
									$offset = "0b0"+$huff -as [int]
									$token_len += $extra_bits
								}
								$matchLength = $value_base + $offset
								if($PSBoundParameters.Verbose){
									Write-Colored -L "&3Backreference Detected..."
									Write-Colored -L "&1$match_bits&r"
									Write-Colored -L ("&0Matched&r &3{0,3}&r &3(&0{1}&3)" -f $match_value,$match_bits)
									Write-Colored -L "&2Length Code&r: &0$token_bits&r &3(&r+$extra_bits bits&3)"
									Write-Colored -L "&0Extra&r: &0$offset&r &3(&7$huff&3)&r"
									Write-Colored -L "&0Value&r: &0$value_base&r"
									Write-Colored -L "&0Final&r: &0$value_base&3 + &0$offset&3 = &1$matchLength&r"								
									Write-Colored "&2----------"
								}
								
								
								$dst_start = $x + $token_len
								$token = -join $test[$dst_start..($dst_start+$LIT_MAX-1)]
								$match_dc = ($Dst_Table | where { $token.StartsWith($_.Item2) })
								$match_value = $match_dc.Item1
								$match_bits = $match_dc.Item2
								$match_lit = $match_dc.Item3
								$match_len = $match_bits.Length
								# Write-Colored -L "&0Matched&r &3$match_value&r"
								# Write-Colored -L "&1$match_bits&r"
								$extra_bits = 0
								$offset = 0
								$huff = $null
								$CodeBase = $CodeTable["{0:D2}" -f $match_value]
								$extra_bits = $CodeBase.Extra
								$value_base = $CodeBase.Value
								if($extra_bits -gt 0){
									$huff_start = $x + $token_len + ($match_dc.Item2.Length)
									$huff = -join $test[($huff_start+$extra_bits-1)..$huff_start]
									$offset = "0b0"+$huff -as [int]
									$token_len += $extra_bits
								}
								$matchDistance = $value_base + $offset
								if($PSBoundParameters.Verbose){
									Write-Colored -L ("&0Matched&r &3{0,3}&r &3(&0{1}&3)" -f $match_value,$match_bits)
									Write-Colored -L "&2Distance Code&r: &0$token_bits&r &3(&r+$extra_bits bits&3)"
									Write-Colored -L "&0Extra&r: &0$offset&r &3(&7$huff&3)&r"
									Write-Colored -L "&0Value&r: &0$value_base&r"
									Write-Colored -L "&0Final&r: &0$value_base &3+ &0$offset &3= &1$matchDistance&r"								
								}
								$tList.Value += , "match $matchLength $matchDistance"
								$token_len += $match_len
							}
							else{
								if($PSBoundParameters.Verbose){
									Write-Colored -L ("&0Matched&r &3{0,3}&r &3(&0{1}&3)" -f $match_value,$match_bits)
								}
								$tList.Value += , "literal $match_value"
							}
							if($PSBoundParameters.Verbose){
								Write-Colored "&2----------"
							}
							
							$TokenNumber++
							
							# Sanity Check for superblocks
							if($TokenNumber -ge 16384){
								Write-colored "&1Too Many Tokens!"
								# Pause
							}
							
							# Handle Unexpected EOS
							if($test.length - $x -lt 32){
								$bitsLeft = [char[]]$test[($x+$token_len)..($test.Length-1)]
								Write-Host ("Last Token:    {0}" -f ($tList.Value[-1]))
								Write-Host ("Bit Remainder: {0}" -f ( -join $bitsLeft)) 
								Pause
								return $true
							}
							else {
								$block_ref.Value = $DefaultBlock
							}
							Pause
						}
						Write-Progress -Activity "Processing Tokens" -Complete
					}
					Fixed {
						for($x=3; $x -lt $test.Length; $x+=8){
							$token = -join $test[$x..($x+8)]
								if(-join $token[0..4] -gt "11000"){ # Greater than 24
								# 9-Bits (144-255)
								$tLen = 9
								$offset = 256
							}
							elseif(-join $token[0..3] -gt  "0010"){ # Greater than  2
								# 8-Bits (000-143)
								$tLen = 8
								if($PSBoundParameters.Verbose){									
									Write-Host "8-1"
								}
								$offset = 48
							}
							elseif(-join $token[0..3] -gt  "1011"){ # Greater than 11
								# 8-Bits (280-287)
								$tLen = 8
								if($PSBoundParameters.Verbose){
									Write-Host "8-2"
								}
							}
							elseif(-join $token[0..3] -lt  "0011"){ # Less than 3
								# 7-Bits (256-279)
								$tLen = 7
								$offset = 23
							}
							else {
								# Error
								$tLen = -1
							}
							if($PSBoundParameters.Verbose){								
								Write-Host "Token is $tLen bits long!"
							}
							
							$token = -join $test[$x..($x+$tLen-1)]
							$bitValue = "0b0"+$token -as [long]
							if($tLen -eq 7){
								if($PSBoundParameters.Verbose){									
									Write-Colored -L "&1$($token)&r"
								}
								if($bitValue -eq 0){
									if($PSBoundParameters.Verbose){
										Write-Colored "&2---------"
										Write-Colored "&6[[EOS]]&r"										
									}
									$tList.Value += , "end"
									$last_x = $x + 7 # Add num last bits
									break
								}
								if($PSBoundParameters.Verbose){									
									Write-Colored -L "&3Backreference Detected..."
								}
								#############################
								$length = $token
								$lengthCode = $bitValue + 256
								$searchKey = $lengthCode -as [string]
								$extra_7 = $CodeTable[$searchKey].Extra
								$value_7 = $CodeTable[$searchKey].Value
								if($PSBoundParameters.Verbose){
									Write-Colored -L "&27-bit Length Code&r: $lengthCode ($length + 256)"
									Write-Host "  Base Value: $value_7"									
								}
								$V7 = $length
								$E7 = [System.Range]::new($x+7,$x+7+$extra_7-1)
								if($E7.Start.Value-1 -ne $E7.End.Value){
									$reversed = -join $test[$E7.Start.Value..$E7.End.Value]
									$reversed = -join $test[$E7.End.Value..$E7.Start.Value]
									$offset_7 = $extra_7
								}
								else{
									$reversed = ""
									$offset_7 = 0
								}
								$E7 = "0b0"+$reversed
								$matchLength = $value_7+$E7
								if($PSBoundParameters.Verbose){									
									Write-Host "  Addend: $($extra_7)-bits --> $reversed ($($E7 -as [int]))"
									Write-Colored "  Match Length: $($value_7) + $($E7 -as [int]) = &1$($matchLength)&r"
								}
								$E7 = $reversed
								if($PSBoundParameters.Verbose){
									Write-Colored -L "&3$($V7)_$($E7)&r"
								}
								#############################
								$V5 = [System.Range]::new($x+7+$extra_7,$x+7+$extra_7+5-1)
								$distance_5 = -join $test[$V5.Start.Value..$V5.End.Value]
								$distanceCode = "0b"+$distance_5 -as [int]
								$searchKey = ($distanceCode -as [string]).PadLeft(2,'0')
								$extra_5 = $CodeTable[$searchKey].Extra
								$value_5 = $CodeTable[$searchKey].Value
								if($PSBoundParameters.Verbose){									
									Write-Colored -L "&25-bit Distance Code&r: $($distanceCode) ($($distance_5))"
									Write-Host "  Base Value: $($value_5)"
								}
								$V5 = $distance_5
								$E5 = [System.Range]::new($x+7+$extra_7+5,$x+7+$extra_7+5+$extra_5-1)
								if($E5.Start.Value-1 -ne $E5.End.Value){
									$reversed = -join $test[$E5.Start.Value..$E5.End.Value]
									$reversed = -join $test[$E5.End.Value..$E5.Start.Value]
									$offset_5 = $extra_5
								}
								else{
									$reversed = ""
									$offset_5 = 0
								}
								$E5 = "0b0"+$reversed
								$matchDistance = $value_5 + $E5
								if($PSBoundParameters.Verbose){
									Write-Host "  Addend: $($extra_5)-bits --> $($reversed) ($($E5 -as [int]))"
									Write-Colored "  Backward Distance: $($value_5) + $($E5 -as [int]) = &1$($matchDistance)&r"									
								}
								$E5 = $reversed
								if($PSBoundParameters.Verbose){
									Write-Colored -L "&1$($V7)_$($E7)_$($V5)_$($E5)&r"									
								}
								$token = -join $test[$x..($x+7+$extra_7+5+$extra_5-1)]
								$x += $token.Length-1
								$x -= 7
								$tList.Value += "match $matchLength $matchDistance"
							}
							else{
								$literal = $bitValue - $offset
								$tList.Value += , "literal $($literal)"
								if($PSBoundParameters.Verbose){
									Write-Colored -L "&1$($token)&r -> $($bitValue) - $($offset) = &1$($literal)&r"									
								}
							}
							if($PSBoundParameters.Verbose){								
								Write-Colored "&2---------"
							}
							if($tLen -eq 9){
								$x+=1;
							}
							# Pause
						}
					}
				}
				$tokens_ref.Value += $tList.Value
				[System.IO.File]::WriteAllBytes("./zStream.bin", $Block);
				$fmt = @(0)
				$last_rem = 0
				$last_bytes = [Math]::DivRem($last_x,8,[ref]$last_rem)
				$blockRef.Value++
				Write-Colored "&1Stats&r: &3$last_x ($last_bytes`:$last_rem)"
				$new_value = -join $test[$last_x..$test.Length]
				Write-Colored -L ("&0{0}...{1}&r" -f ($new_value.Substring(0,32),$new_value.Substring($new_value.Length-32)))
				$bitstream_ref.Value = $new_value
				if($bFinal -eq '1'){
					return $true
				}
			}
			
			$cond = $false
			while(-not $cond){
				$cond = Read-ZLIB_Block $test -Verbose
			}
			$fmt = @(0)
		}
	}
	
	$tmp = 0;
	$tmpRef = [ref]$tmp
	for( $i=0; $i -lt ($fmt.Length); $i++){
		$len = $fmt[$i]
		if($len -eq 0){ break }
		$new = $tmp + $len
		$hex = [Convert]::ToHexString($Block[$tmp..($new-1)])
		$str = "&u&o&0$hex&r  "
		$print += $str
		
		$t2 = $Block[$tmp..($new-1)]
		switch($t2.Length){
			4{
				$outRef.Value += [BitConverter]::ToInt32($Block[($new-1)..$tmp],0)
			}
			1{
				$outRef.Value += [Byte]::Parse(-join $t2)
			}
			default {
				$outRef.Value += [Encoding]::ASCII.GetString($t2)
			}
		}
		$tmp += $len
	}
	
	if($ChunkType -notin "IDAT","IEND"){		
		Write-Colored -L "&2FMT&r: $print"
		Write-Colored -L "&2Out&r: $out`n"
	}
	
	$stats = $out | Measure-Object -Maximum
	$pad = "$($stats.Maximum)".Length
	Write-Colored "&2$ChunkType`n&2$('-'*($pad+20))"
	switch($ChunkType){
		"IHDR"{
			$width_ref = [ref]$IMAGE_WIDTH;
			$lines_ref = [ref]$IMAGE_LINES;
			$width_ref.Value = $out[0]
			$lines_ref.Value = $out[1]
			Write-Colored ((
				"&6Width:              &1{0,$pad}`n"+
				"&6Height:             &1{1,$pad}`n"+
				"&6Bit depth:          &1{2,$pad}`n"+
				"&6Color type:         &1{3,$pad}`n"+
				"&6Compression method: &1{4,$pad}`n"+
				"&6Filter method:      &1{5,$pad}`n"+
				"&6Interlace method:   &1{6,$pad}`n") -f $out
			)
		}
		"sRGB"{
			Write-Colored ((
				"&6Rendering Intent:   &1{0,$pad}`n") -f $out
			)
		}
		"eXIf"{
			Write-Colored ((
				"&6EXIF Binary&r: &2./Exif.bin`n")
			)
		}
		"pHYs"{
			Write-Colored ((
				"&6Pixels Per Unit X:  &1{0,$pad}`n"+
				"&6Pixels Per Unit Y:  &1{1,$pad}`n"+
				"&6Unit Specifier:     &1{2,$pad}`n") -f $out
			)
		}
		"tEXt"{
			Write-Colored ((
				"&6{0}&r: &1{2}`n") -f $out
			)
		}
		"IDAT" {
			Write-Colored -L "&6DAT&r: &0byte[$BlockSize] &3> &0./zStream.bin`n"
		}
		"IEND"{
			# Break
		}
	}
	$crc = [byte[]](Read-Next -count 4)
	$hex = [System.BitConverter]::ToString($crc)
	Write-Colored -L "&5CRC&r: &3$crc&r | &3$hex"
	if($ChunkType -eq "IEND"){
		break
	}
	# Pause
}

###########################
##                       ##
##   Setup & Read File   ##
##                       ##
###########################

$filePath = "$($PSScriptRoot)\$($args[0])"
$bytes = [File]::ReadAllBytes($filePath)
$hex = ([System.BitConverter]::ToString($bytes))
Write-Colored (
	"&2File:`n-----`n&r$filePath`n"+
	"&2Bytes:`n------&r"
)
Pretty-Print -text $hex -interval 48

# Write-Host "Position: ",$readPos -ForegroundColor DarkGreen
Check-Signature
# Write-Host "Position: ",$readPos -ForegroundColor DarkGreen

while($true) {
	Write-Colored "&6----------"
	Read-Block
}
# Pause

###########################
##                       ##
##  Process zLib Tokens  ##
##                       ##
###########################

# $TOKEN_LIST
$TOKEN_LIST > ./tokens.def

$BYTES_PER_PIXEL = 4
function Get-Inflated {
	[CmdletBinding()]
	param()
	$out = [ArrayList]@()
	$x = 0;
	$filtered = $TOKEN_LIST | where { $_ -match "^(literal|match)" }
	$num_tokens = $filtered.Length-1
	foreach($token in $filtered){
		$PC = [Math]::Clamp($x/$num_tokens * 100, 0, 100)
		Write-Progress `
		-Activity "Inflating" `
		-Status "$x of $num_tokens" `
		-PercentComplete $PC `
		# $token
		$msg = "Token: $token`n"
		$parts = $token.Split(' ')
		if($parts[0] -eq "match"){
			$len = $parts[1] -as [int]
			$dst = $parts[2] -as [int]
			if($len -ge $dst){
				$rem = 0
				$quo = [Math]::DivRem($len,$dst,[ref]$rem)
				$msg += "$len / $dst = $quo R $rem`n"
				$copy = $out[(-$dst)..(-1)]
				0..($quo-1) | foreach {
					$msg+= "copy $copy`n"  
					[void]$out.AddRange($copy)
				}
				if($rem -gt 0){
					$msg += "copy $($copy[0..($rem-1)])`n"
					[void]$out.AddRange($copy[0..($rem-1)])
				}
			}
			else{
				$copy = $out[(-$dst)..(-$dst + $len - 1)]
				$msg += "copy $copy`n"
				[void]$out.AddRange($copy)
			}
			# Pause
		}
		elseif($parts[0] -eq "literal"){
			$lit = $parts[1] -as [string]
			$msg += "literal $lit`n"
			[void]$out.add($lit)
		}
		else{
			$msg += "Skipping token $token"
		}
		if($PSBoundParameters.Verbose){
			Write-Host $msg	  
		}
		$x++;
		# Pause
	}
	Write-Progress -Activity "Inflating" -Status "Writing File..."
	$out > Inflated.txt
	Write-Progress -Activity "Inflating" -Complete
}

Get-Inflated

###########################
##                       ##
## Display Inflated File ##
##                       ##
###########################
enum FilterType {
  None    = 0
  Sub     = 1
  Up      = 2
  Average = 3
  Paeth   = 4
}

function Get-Scan_Lines {
	Write-Host "[Process]::Get-Scan_Lines()"
	$scanLines = @()
	for($x=0; $x -lt $bytes.Length; $x+=$lineSize){
	  $scanLines += , $bytes[$x..($x+$lineSize-1)]
	}
	$scanLines
}

function Display { param($arr) 
	$msg = ""
	for($x=0; $x -lt $arr.Length; $x+=4){
		$R = $arr[$x+0]
		$G = $arr[$x+1]
		$B = $arr[$x+2]
		$A = $arr[$x+3]
		$msg += ($A -eq 0) ? "  " : "$($PSStyle.Background.FromRgb($R,$G,$B))  $($PSStyle.Reset)"
	}
	Write-Host $msg
}

function PaethPredictor {
  param(
    $a, # Left
    $b, # Above
    $c  # Upper Left
  )
  # Initial Estimate
  $p = $a + $b - $c
  # Distances to A,B,C
  $pa = [Math]::Abs($p-$a)
  $pb = [Math]::Abs($p-$b)
  $pc = [Math]::Abs($p-$c)
  if($pa -le $pb -and $pa -le $pc){ $a }
  elseif($pb -le $pc){ $b }
  else { $c }
}

function Process-Filters {
	param($scanLines)
	$LINES = $scanLines.Count
	$BYTES = $scanLines[0].Count
	Write-Host ("[Process]::Process-Filters({0} `$scanLines[{1}][{2}])" -f $scanLines.GetType().Name,$LINES,$BYTES)
	$prior = New-Object int[] ($lineSize-1)
	
	Write-Colored ("  " + -join (1..$IMAGE_WIDTH | ForEach({ "{0}{1:X2}&r" -f ([int]::IsEvenInteger($_) ? "&2" : "`e[90m"),$_})))
	("[Process]::Process-Filters(`$scanLines``{0}[]``{1}[])" -f $LINES,$BYTES) >> SCAN.txt
	for($y=0; $y -lt $LINES; $y++){
	  $PC0 = $y / $LINES * 100
	  Write-Progress -Activity "ScanLines" -Id 0 -Status "$y of $LINES" -PercentComplete $PC0
	  $line = $scanLines[$y]
	  $raw = New-Object int[] ($lineSize-1)
	  switch($line[0]){
		{$_ -eq [FilterType]::None    } { $raw   = $line[1..$lineSize] }
		{$_ -eq [FilterType]::Sub     } { $sub   = $line[1..$lineSize]
		  for($x=0; $x -lt $sub.Length; $x++){
			$PC1 = $x / $BYTES * 100;
			Write-Progress -Activity "DataBytes" -Id 1 -ParentId 0 -Status "$x of $BYTES" -PercentComplete $PC1;
			if($x-$BYTES_PER_PIXEL -lt 0) { 
				$raw[$x] = $sub[$x]
				continue
			}
			$raw[$x] = ($sub[$x] + $raw[$x-$BYTES_PER_PIXEL]) % 256;
		  }
		  <# Sub(x) + Raw(x-bpp) #>	}
		{$_ -eq [FilterType]::Up      } { $up    = $line[1..$lineSize]
		  for($x=0; $x -lt $up.Length; $x++){
			$PC1 = $x / $BYTES * 100
			Write-Progress -Activity "DataBytes" -Id 1 -ParentId 0 -Status "$x of $BYTES" -PercentComplete $PC1
			$raw[$x] = ($up[$x] + $prior[$x]) % 256
		  }
		  <# Up(x) + Prior(x) #>
		}
		{$_ -eq [FilterType]::Average } { $avg   = $line[1..$lineSize]
		  for($x=0; $x -lt $avg.Length; $x++){
			$PC1 = $x / $BYTES * 100
			Write-Progress -Activity "DataBytes" -Id 1 -ParentId 0 -Status "$x of $BYTES" -PercentComplete $PC1
			$a = [Math]::Max($raw[$x-$BYTES_PER_PIXEL],0)
			$b = $prior[$x]
			Write-Host "$a, $b"
			$raw[$x] = ($avg[$x] + [Math]::Floor(($a + $b) / 2)) % 256
		  }
		  <# Average(x) + floor((Raw(x-bpp)+Prior(x))/2) #>
		}
		{$_ -eq [FilterType]::Paeth   } { $paeth = $line[1..$lineSize]
		  for($x=0; $x -lt $paeth.Length; $x++){
			$PC1 = $x / $BYTES * 100
			Write-Progress -Activity "DataBytes" -Id 1 -ParentId 0 -Status "$x of $BYTES" -PercentComplete $PC1
			$a = [Math]::Max(  $raw[$x-$BYTES_PER_PIXEL],0)
			$c = [Math]::Max($prior[$x-$BYTES_PER_PIXEL],0)
			$b = $prior[$x]
			$raw[$x] = ($paeth[$x] + (PaethPredictor $a $b $c)) % 256
		  }
		  <# Paeth(x) + PaethPredictor(Raw(x-bpp), Prior(x), Prior(x-bpp)) #>
		}
	  }
	  Write-Host ("{0:D2}" -f ($y+1)) -NoNewLine
	  $prior = $raw
	  Display $raw
	  $raw >> SCAN.txt
	}
	Write-Progress -Id 0 -Activity "ScanLines" -Completed 
	Write-Progress -Id 1 -ParentId 0 -Activity "DataBytes" -Completed 
}

$BYTES_PER_PIXEL = 4
$bytes = -split [File]::ReadAllText("$($PSScriptRoot)\Inflated.txt") -as [byte[]]
$lineSize = $IMAGE_WIDTH*$BYTES_PER_PIXEL+1
$ScanLines = Get-Scan_Lines
Write-Host ( [BitConverter]::ToString($ScanLines[0]) ).Substring(0,1024)
Pause
Process-Filters $ScanLines