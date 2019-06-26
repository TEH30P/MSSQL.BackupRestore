@{
  'OV-MSSQLBkp'= @{
    'SV-SrvInst'= 'dummy\\sql';
    'SV-DBName'= 'dummydb';
    'OV-LangolierRule'= @{
      'SL-DataRtn'= @{
        'V-Is'= 'P7D';
        'SV-Layer'= '0'
      };
      'SV-TlogRtn'= @{
        'V-Is'= 'P1D'
      }
    };
    'SL-Repo'= @(
      'file://a:/dummy0'
    , 'file://a:/dummy1'
    );
    'OV-DataBkpRule'= @{
      'SV-DiffFullRatioMax'= 0.25;
      'SV-DiffSizeFactor'= 3.0;
      'SV-TotalSizeMax'= 128TB;
      'SV-Duration'= 'P1DT12H';
      'SV-ArcLayer'= 0;
      'SV-OperAllow'= 'df'
    };
    'OV-TLogBkpRule'= @{
      'SV-Duration'= 'PT14H';
      'SV-ChkPeriod'= 'PT5M';
      'SV-AgeTrg'= 'PT15M';
      'SV-UsageMinTrg'= 512MB;
      'SV-UsageMaxTrg'= 1GB
    }
  }
}