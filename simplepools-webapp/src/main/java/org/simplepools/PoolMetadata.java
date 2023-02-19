package org.simplepools;

import com.fasterxml.jackson.annotation.JsonAutoDetect;

import java.math.BigInteger;

@JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY)
public class PoolMetadata {
   public final BigInteger poolId;
   public final String asset1Name;
   public final String asset1Symbol;
   public final String asset1Decimals;
   public final String asset2Name;
   public final String asset2Symbol;
   public final String asset2Decimals;
   public final String currentPriceFor1Asset1InAsset2;

   public PoolMetadata(
          BigInteger poolId,
          String asset1Name,
          String asset1Symbol,
          String asset1Decimals,
          String asset2Name,
          String asset2Symbol,
          String asset2Decimals,
          String currentPriceFor1Asset1InAsset2
   ) {
      this.poolId = poolId;
      this.asset1Name = asset1Name;
      this.asset1Symbol = asset1Symbol;
      this.asset1Decimals = asset1Decimals;
      this.asset2Name = asset2Name;
      this.asset2Symbol = asset2Symbol;
      this.asset2Decimals = asset2Decimals;
      this.currentPriceFor1Asset1InAsset2 = currentPriceFor1Asset1InAsset2;
   }

}
