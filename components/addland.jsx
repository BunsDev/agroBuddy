'use client'
import React, { useState } from 'react';
import { start} from "../utils";
import AllCrop from "./allcrop";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

const AddLand = () => {
  const [details, setDetails] = useState({
    area: "",
    rentamount: "",
    days: "",
  });

  const [isLoading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setDetails((prev) => {
      return { ...prev, [name]: value };
    });
  };

   const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const rentamount = BigInt(details.rentamount);
      const days = BigInt(details.days);
      setLoading(true);
      const transactionResponse = await start(details.area, rentamount, days );
      console.log(transactionResponse);
      const transactionHash = transactionResponse.hash;
      console.log("Transaction Hash:", transactionHash);
      toast.success(transactionHash);
      toast.success("Land Added Successfully");
      console.log("Land Added Successfully");
      setLoading(false);
    } catch (error) {
      console.error("Error adding Land:", error.message);
      toast.error("Error adding Land: " + error.message);
    }
    console.log(details);
  };

  return (
    <div className="flex justify-center relative ">
      <ToastContainer />
      <form className='p-12 bg-white rounded-lg shadow-black shadow-2xl' onSubmit={handleSubmit}>
  <h1 className="text-5xl mb-6 text-[#209d4c]">Add Land</h1>
  <label htmlFor="area" className='text-[#209d4c]'>Area:</label><br />
  <input
    type="text"
    id="area"
    name="area"
    value={details.area}
    onChange={handleChange}
    placeholder="Enter the area"
    style={{ textAlign: 'left' }}
    className="px-5 py-2 w-72 border border-gray-300 bg-white text-black rounded"
  /><br /><br />

  <label htmlFor="price" className='text-[#209d4c]'>Amount:</label><br />
  <input
    type="text"
    id="rentamount"
    name="rentamount"
    placeholder="Enter the amount"
    value={details.price}
    onChange={handleChange}
    style={{ textAlign: 'left' }}
    className="px-5 py-2 w-72 border border-gray-300 bg-white text-black rounded"
  /><br /><br />

  <label htmlFor="days" className='text-[#209d4c]'>Number Of Days:</label><br />
  <input
    type="text"
    id="days"
    name="days"
    placeholder="Enter the days"
    value={details.days}
    onChange={handleChange}
    style={{ textAlign: 'left' }}
    className="px-5 py-2 w-72 border border-gray-300 bg-white text-black rounded"
  /><br /><br />

  {isLoading ? (
    <button
      type="submit"
      disabled={isLoading}
      className="px-10 py-2 mt-4 text-lg font-medium text-center bg-[#e8f4ec] text-[#219d4d] border-2 border-[#219d4d] hover:bg-[#219d4d] hover:text-white transition ease-in-out duration-500 whitespace-nowrap rounded-md"
    >
      ...
    </button>
  ) : (
    <button
      type="submit"
      disabled={isLoading}
      className="px-10 py-2 mt-4 text-lg font-medium text-centerbg-[#e8f4ec] text-[#219d4d] border-2 border-[#219d4d] hover:bg-[#219d4d] hover:text-white transition ease-in-out duration-500 whitespace-nowrap rounded-md"
    >
      Submit
    </button>
  )}
</form>


    </div>
  );
};

export default AddLand;
