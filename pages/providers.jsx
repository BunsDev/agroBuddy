
import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { WagmiConfig } from "wagmi"; // Make sure to import WagmiConfig
import { mainnet, polygon, opBNBTestnet, bscTestnet } from "wagmi/chains";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import React, { useState, useEffect } from "react"; // Import useState and useEffect

const config = getDefaultConfig({
    appName: "My RainbowKit App",
    projectId: "95f8ce26a83baf6d9b6db95a07e082a1",
    chains: [opBNBTestnet, bscTestnet],
    ssr: false, // If your dApp uses server side rendering (SSR)
});

const queryClient = new QueryClient();

export default function Providers({ children }) { // Ensure default export
    const [mounted, setMounted] = useState(false);
    useEffect(() => setMounted(true), []);
    
    return (
        <WagmiConfig config={config}>
            <QueryClientProvider client={queryClient}>
                <RainbowKitProvider>
                    {mounted && children}
                </RainbowKitProvider>
            </QueryClientProvider>
        </WagmiConfig>
    );
}


