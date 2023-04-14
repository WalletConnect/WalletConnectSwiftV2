import '@walletconnect/react-native-compat';
import '@ethersproject/shims';
import React from 'react';
import {
    AppRegistry,
    Text,
    View
  } from 'react-native';

import { Web3Button, Web3Modal } from '@web3modal/react-native'

const Web3ModalBridge = () => {
  return (
    <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
      <Web3Button />
      <Web3Modal projectId='90369b5c91c6f7fffe308df2b30f3ace' />
    </View>
  );
}

AppRegistry.registerComponent('Web3ModalBridge', () => Web3ModalBridge);