@{
  'OV-MSSQLBkp'= @{
    'SV-SrvInst'= @{
      'V-Is'= 'dummy\\sql'
    };
    'OV-ArchRule'= @{
      'SL-DataRtn'= @{
        'V-Is'= 'P7D';
        'SV-Layer'= '0'
      };
      'SV-TlogRtn'= @{
        'V-Is'= 'P1D'
      }
    };
    'SL-DBName'= 'dummydb';
    'SL-Repo'= @(
      'file://a:/dummy0';
      'file://a:/dummy1'
    );
    'OV-DataBkpRule'= @{
      'SV-DiffFullRatioMax'= 0.25;
      'SV-DiffSizeFactor'= 3.0;
      'SV-Duration'= 'P1DT12H';
      'SV-ArcLayer'= 0;
      'SV-OperAllow'= 'df'
    };
    'OV-TLogBkpRule'= @{
      'SV-Duration'= 'PT14H';
      'SV-ChkPeriod'= 'PT5M';
      'SV-AgeTrg'= 'PT15M';
      'SV-UsageMinTrg'= '512M';
      'SV-UsageMaxTrg'= '1G'
    }
  }
}