'use client'
import 
React, { useState, useEffect } from "react";
import { getUserAddress, setPrice, getAllRequest , switchNetworkToFuji } from "../utils";
import Toggle from "../pages/toggle";
const AllBorrowReq = () => {
  const [farmerAddress, setFarmerAddress] = useState(null);
  const [borrowData, setBorrowData] = useState([]);
  const [isUserSignIn, setIsUserSignIn] = useState(false);
  const [priceMap, setPriceMap] = useState({});
  const [isLoading, setLoading] = useState(false);
  const [loadingPrice, setLoadingPrice] = useState({});

  useEffect(() => {
    const checkUserSignIn = async () => {
      setLoading(true);
      const address = await getUserAddress();
      setLoading(false);
      if (address) {
        setFarmerAddress(address);
        setIsUserSignIn(true);
      }
    };
    checkUserSignIn();
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      if (isUserSignIn) {
        setLoading(true);
        const borrowRequests = await getAllRequest();
        setLoading(false);
        console.log(borrowRequests);
        setBorrowData(borrowRequests);
      }
    };
    fetchData();
  }, [isUserSignIn]);

  const handleSetPrice = async (requestId) => {
    const price = priceMap[requestId];
    if (!price) {
      console.error("Price is not defined");
      return;
    }

    let priceBigInt;
    try {
      priceBigInt = BigInt(price);
    } catch (error) {
      console.error("Invalid price value:", error);
      return;
    }

    try {
      setLoadingPrice((prev) => ({ ...prev, [requestId]: true }));
      await setPrice(requestId, priceBigInt);
      console.log("Price set successfully");
      setLoadingPrice((prev) => ({ ...prev, [requestId]: false }));
    } catch (error) {
      console.error("Failed to set price:", error);
      setLoadingPrice((prev) => ({ ...prev, [requestId]: false }));
    }
  };

  const handlePriceChange = (requestId, value) => {
    setPriceMap((prev) => ({
      ...prev,
      [requestId]: value,
    }));
  };

  return (
    <div>
    <div className="mt-28 mx-6 absolute left-[28rem] top-10">
      
    <div className="bg-white shadow-md rounded-lg overflow-hidden w-[32rem]">
    <div className="bg-[#fcf7ea] border-b border-gray-200  text-xs font-semibold uppercase tracking-wider text-gray-500">
    <div className="flex p-4">
            
    <div className="w-1/4">Items</div>
    <div className="w-1/4">Days</div>
    <div className="w-1/4">Set Price</div>
    <div className="w-1/4">Action</div>
    </div> 
    </div>    
    {borrowData.length > 0 ? (
              borrowData.map((borrow) => (
              <div
                key={borrow.requestId}
                className="border-b border-gray-200 text-gray-700"
              >
                <div className="flex items-center p-[1.5%] hover:bg-gray-50">
                  <div className="w-1/4"> {borrow._itemName}</div>
                  <div className="w-1/4"> {borrow._timePeriod}</div>
                  <div className="px-4 py-1 whitespace-nowrap text-sm text-gray-900">
                    <input
                      type="text"
                      placeholder="Set price"
                      value={priceMap[borrow.requestId] || ""}
                      onChange={(e) =>
                        handlePriceChange(borrow.requestId, e.target.value)
                      }
                      className="border border-gray-300 rounded py-1 px-2 w-24 -ml-[22%]"
                    />
                  </div>
                  <div className="w-1/4 flex">
                  <button
                      className={`px-2 py-[1%] rounded-md text-[#219d4d] ${
                        loadingPrice[borrow.requestId]
                            ? "bg-gray-100  cursor-not-allowed"
                            : "bg-[#e8f4ec]  text-[#219d4d] border-2 border-[#219d4d] hover:bg-[#219d4d] hover:text-white transition ease-in-out duration-500 whitespace-nowrap"
                        }`}
                      onClick={() => handleSetPrice(borrow.requestId)}
                      disabled={loadingPrice[borrow.requestId]}
                    >
                      
                      {loadingPrice[borrow.requestId] ? "..." : "Set Price"}
                    </button>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="p-4 text-center text-gray-500">
               No borrow requests available
            </div>
          )}
        </div>
        {/* <ToastContainer /> */}
      </div>
    </div>

  );
};

export default AllBorrowReq;
