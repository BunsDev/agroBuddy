'use client'
import React, { useState } from 'react';
import AllLand from "../components/allland";
import AllBorrowReq from "../components/allborrowreq";
import  {switchNetworkToFuji , getUserAddress} from "../utils";
const ToggleButton = () => {
  const [userAddress, setUserAddress] = useState(null);
  const [isLand, setIsLand] = useState(true);

  const handleLandClick = async () => {
    await switchNetworkToFuji();
    const address = await getUserAddress();
    setUserAddress(address);
    setIsLand(true);
  };

  const handleCommoditiesClick = () => {
    setIsLand(false);
  };

  return (
    <div className="flex items-center justify-center min-h-screen max-h-full bg-gray-100">
      <div className="absolute top-20 flex items-center rounded-full shadow-lg p-2">
        <button
          onClick={handleLandClick}
          className={`px-4 py-2 rounded-full focus:outline-none transition-colors ${
            isLand ? 'bg-[#219d4d]' : 'bg-gray-400'
          } text-white`}
        >
          Land
        </button>
        <button
          onClick={handleCommoditiesClick}
          className={`px-4 py-2 rounded-full focus:outline-none transition-colors ${
            !isLand ? 'bg-[#219d4d]' : 'bg-gray-400'
          } text-white`}
        >
          Items
        </button>
      </div>
      <div className="mt-20 w-full">
        {isLand ? <AllLand /> : <AllBorrowReq />}
      </div>
    </div>
  );
};

export default ToggleButton;
