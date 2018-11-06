@{
	'OV-MSSQLBkp'= @{
		'SV-SrvInst'= @{ 'V-Is'= 'dummy\\sql' };
		'SL-DBName'= 'dummydb';
	  'SL-Repo'= @('file://a:/dummy0', 'file://a:/dummy1');
	  'OV-RuleDef'= @{
			'SV-DiffFullRatioMax'= '0.25';
			'SV-DiffSizeFactor'= '3';
			};
	  'OL-Rule'= @(
		@{
		  'SV-DiffFullSizeMax'= '2G';
		  'OL-DataBkpDTW'= @(
			@{
			  'SV-Begin'= 'FD~sat~T04:00:00';
			  'SV-Duration'= 'P1DT12H';
			  'SV-ArcLayer'= '0';
			  'SV-OperAllow'= 'df';
			},
			@{
			  'SV-Begin'= 'FD~!sat~!sun~T04:00:00';
			  'SV-Duration'= 'PT2H';
			  'SV-ArcLayer'= '0';
			  'SV-OperAllow'= 'd';
			}
		  );
		  'OL-TlogBkpDTW'= @(
			@{
			  'SV-Begin'= 'FD~T08:30:00';
			  'SV-Duration'= 'PT9H';
			  'SV-Period'= 'FT~15M';
			},
			@{
			  'SV-Begin'= 'FD~T18:30:00';
			  'SV-Duration'= 'PT14H';
			  'SV-Period'= 'FT~5M';
			  'SV-UsageTrg'= '512M';
			}
		  );
		  'OV-Arch'= @{
			'SL-DataRtn'= @{
			  'V-Is'= 'P7D';
			  'SV-Layer'= '0';
			};
			'SV-TlogRtn'= @{ 'V-Is'= 'P1D' }
		  }
		};
		@{
		  'SV-SrvInst'= 'dummy\\sql';
		  'SL-DBName'= 'master';
		  'SV-DiffFullSizeMax'= '1G';
		  'OL-DataBkpDTW'= @{
			'SV-Begin'= 'FD';
			'SV-Duration'= 'PT1H';
			'SV-ArcLayer'= '0';
			'SV-OperAllow'= 'df';
		  };
		  'OV-Arch'= @{
			'SL-DataRtn'= @{
			  'V-Is'= 'P3D';
			  'SV-Layer'= '0';
			}
		  }
		}
	  )
	}
  }