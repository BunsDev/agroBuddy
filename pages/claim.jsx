'use client';
import React, { useState, useEffect } from 'react';
import Footer from "../components/footer";
import { getUserAddress, callRequestClaim, callClaim, calculateUSD, getAllFarmers } from "../utils";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

const Claim = () => {
  const [farmerAddress, setFarmerAddress] = useState(null);
  const [isUserSignIn, setIsUserSignIn] = useState(false);
  const [area, setArea] = useState(null);
  const [state, setState] = useState(null);
  const [country, setCountry] = useState(null);
  const [farmersData, setFarmersData] = useState([]);
  const [isLoading, setLoading] = useState(false);
  const [isLoading1, setLoading1] = useState(false);
  const [isLoading2, setLoading2] = useState(false);
  const [claimValue, setClaimValue] = useState(null);

  useEffect(() => {
    setIsUserSignIn(true);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      if (isUserSignIn) {
        setLoading2(true);
        try {
          const userAddress = await getUserAddress();
          const data = await getAllFarmers();
          setFarmersData(data);
          const userFarmer = data.find(farmer => farmer.farmerAddress.toLowerCase() === userAddress.toLowerCase());
          if (userFarmer) {
            const { farmerAddress, area, state, country } = userFarmer;
            setFarmerAddress(farmerAddress);
            setArea(area);
            setState(state);
            setCountry(country);
          } else {
            toast.error("Farmer not found for the current user.");
          }
        } catch (error) {
          console.error("Error fetching farmers data:", error);
          toast.error("Error fetching farmers data.");
        } finally {
          setLoading2(false);
        }
      }
    };

    fetchData();
  }, [isUserSignIn]);

  const handleRequest = async () => {
    setLoading1(true);
    try {
      await callRequestClaim();
      toast.success("Farmer Request for Claim!");
    } catch (error) {
      console.error("Error requesting claim:", error);
      toast.error("Error requesting claim.");
    } finally {
      setLoading1(false);
    }
  };

  const handleClaim = async () => {
    setLoading(true);
    try {
      await callClaim("true");
      const calculatedClaimValue = await calculateUSD(area);
      setClaimValue(calculatedClaimValue);
      toast.success("Farmer claimed successfully!");
    } catch (error) {
      console.error("Error during claim:", error);
      toast.error("Error during claim.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <ToastContainer />
      <section className="w-full">
        <div className="h-32 flex justify-center items-center text-5xl w-full ">
          {/* Header section */}
        </div>
        <h1 className="hover-effect flex items-center gap-x-3 font-raleway text-4xl font-semibold tracking-tight relative top-0 ml-10">
          <span className="text-[#ebab2d]">Claim</span> 
          <span className="text-[#219d4d]">Dashboard</span>
        </h1>

        <div className="my-6 flex justify-between relative -top-14 right-5">
          <div className="flex items-center gap-x-6 absolute left-[75%]">
            <button
              className="flex items-center gap-x-1 rounded-lg px-2 py-1 font-medium tracking-tight text-secondary text-2xl bg-[#fcf7ea] text-[#ebab2d] border-2 border-[#ebab2d] hover:bg-[#ebab2d] hover:text-white whitespace-nowrap transition ease-in-out duration-500"
              onClick={handleRequest}
              disabled={isLoading1}
            >
              {isLoading1 ? "..." : "Request Claim"}
            </button>

            <button
              className="flex items-center gap-x-1 rounded-lg px-6 py-1 font-medium tracking-tight text-2xl bg-[#e8f4ec] text-[#219d4d] border-2 border-[#219d4d] hover:bg-[#219d4d] hover:text-white transition ease-in-out duration-500"
              onClick={handleClaim}
              disabled={isLoading}
            >
              {isLoading ? "Processing..." : "Claim"}
            </button>
          </div>
        </div>
      </section>
      <section className="p-page my-14 flex justify-between w-full">
        <div className="mx-auto flex w-[40%] h-[26rem] flex-col items-center rounded-[3rem] bg-foreground p-4 relative left-24 bg-[#e8e9e9]">
          <div className="border-8 border-[#219d4d] w-[23rem] h-96 rounded-full flex items-center justify-center">
            <div className="bg-[#565657] w-[21rem] h-[22rem] rounded-full flex items-center justify-center">
              <p className="text-xl text-white">{`Claim value is: ${claimValue ? claimValue : "0"}`}</p>
            </div>
          </div>
        </div>
        <div className="relative right-10">
          {farmersData.length > 0 ? (
            farmerAddress ? (
              <div className="border-b bg-gray-100 hover:bg-gray-200 ease-in-out duration-500 rounded-lg">
                <div className="p-4">{`Farmer Address: ${farmerAddress}`}</div>
                <div className="p-4">{`Area: ${area}`}</div>
                <div className="p-4">{`State: ${state}`}</div>
                <div className="p-4">{`Country: ${country}`}</div>
              </div>
            ) : (
              <p>No farmer details found</p>
            )
          ) : (
            <p>No farmers found</p>
          )}
        </div>
      </section>
      <Footer />
    </div>
  );
};

export default Claim;
