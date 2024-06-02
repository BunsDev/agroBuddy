'use client'
import React, { useState } from 'react';
import { addCrop, getAllCrop , } from "../utils";
import AllCrop from "../components/allcrop";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

const AddCrop = () => {
  const [details, setDetails] = useState({
    cropName: "",
    price: "",
    quantity: "",
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
      const price = BigInt(details.price);
      const quantity = BigInt(details.quantity);
      setLoading(true);
      await addCrop(details.cropName, price, quantity);
       toast.success("Crops Added Successfully");
      console.log("Crop Added Successfully");
      const crops = await getAllCrop();
      console.log("All Crops:", crops);
      setLoading(false);
    } catch (error) {
      console.error("Error adding crop:", error);
      toast.error("Error adding crop: " + error.message);
      setLoading(false);
    }
    console.log(details);
  };

  return (
    <div className="flex justify-center relative ">
      <ToastContainer />
      <form className='p-12 bg-white rounded-lg shadow-black shadow-2xl ' onSubmit={handleSubmit}>
        <h1 className="text-5xl mb-12 text-[#ebab2d] ">Add Crop</h1>
        <label htmlFor="cropName" className='text-[#ebab2d]'>Crop Name:</label><br />
        <input
          type="text"
          id="cropName"
          name="cropName"
          value={details.cropName}
          onChange={handleChange}
          placeholder="Enter crop name"
          className="px-5 py-2 w-72 border border-gray-300 bg-white text-black rounded"
        /><br /><br />

        <label htmlFor="price" className='text-[#ebab2d]'>Price:</label><br />
        <input
          type="text"
          id="price"
          name="price"
          placeholder="Enter the price"
          value={details.price}
          onChange={handleChange}
          className="px-5 py-2 w-72 border border-gray-300 bg-white text-black rounded"
        /><br /><br />

        <label htmlFor="quantity" className='text-[#ebab2d]'>Quantity (in Kg):</label><br />
        <input
          type="text"
          id="quantity"
          name="quantity"
          placeholder="Enter the quantity"
          value={details.quantity}
          onChange={handleChange}
          className="px-5 py-2 w-72 border border-gray-300 bg-white text-black rounded"
        /><br /><br />

        {isLoading ? (
          <button
            type="submit"
            disabled={isLoading}
            className="px-10 py-2 mt-4 text-lg font-medium text-center bg-[#fcf7ea] text-[#ebab2d] border-2 border-[#ebab2d] hover:bg-[#ebab2d] hover:text-white whitespace-nowrap transition ease-in-out duration-500  rounded-md"
          >
            ...
          </button>
        ) : (
          <button
            type="submit"
            disabled={isLoading}
            className="px-10 py-2 mt-4 text-lg font-medium text-center bg-[#fcf7ea] text-[#ebab2d] border-2 border-[#ebab2d] hover:bg-[#ebab2d] hover:text-white whitespace-nowrap transition ease-in-out duration-500 rounded-md"
          >
            Submit
          </button>
        )}
      </form>
    </div>
  );
};

export default AddCrop;
