# kc - Kerberos ccache manager

## Commands

  * `kc` - list ccaches
  * `kc <name>` - select ccache by name or number
  * `kc new` - select a new ccache with generated name
  * `kc purge` - destroy ccaches with expired TGTs
  * `kc destroy <name>` - destroy selected ccaches

## Example output

    $ kc
    » 1 @               grawity@NULLROUTE.EU.ORG                        Jun 12 21:19
      2 8zRpuA          grawity@CLUENET.ORG                             Jun 13 01:32
      3 cn              grawity@CLUENET.ORG                             Jun 12 21:00

In the example above, the "default" ccache (`/tmp/krb5cc_$UID`) is selected as `$KRB5CCNAME`.
