'use client'
import React, { useState } from "react";
import country from "../components/countries";
import Footer from "../components/footer";
import { getUserAddress, register, getAllFarmers } from "../utils";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

const SignIn = () => {
  const [details, setDetails] = useState({
    _area: "",
    _state: "",
    _country: "",
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setDetails((prev) => {
      return { ...prev, [name]: value };
    });
  };

  const [isLoading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      setLoading(true);
      const { _state } = details;
      const formattedDetails = [ _state];
      console.log("Formatted details:", formattedDetails);
      await register(details._area,formattedDetails , details._country);
      console.log("Farmer is registered");
      //getUserAddress();
      getAllFarmers();
      setLoading(false);
      const notify = () => toast("Registration Successfull!");
      notify();
    } catch (error) {
      console.error("Error registering farmer:", error);
    }
    console.log(details);
  };

  return (
    <div className="space-y-20">
      <div>
        <img
          src="/images/illustrations/contact-bg.jpg"
          alt=""
          className="w-full h-screen"
        />
      </div>
      <ToastContainer />
      <div className="flex  absolute top-9 left-36 ">
        <form
          className="p-20 bg-[#fff9e7] rounded-lg shadow-black shadow-2xl"
          onSubmit={handleSubmit}
        >
          <h1 className="text-5xl mb-6 text-[#53321c]">Registration</h1>
          <label htmlFor="area" className="text-[#53321c]">
            Area:
          </label>
          <br />
          <input
            type="text"
            id="_area"
            name="_area"
            value={details._area}
            onChange={handleChange}
            placeholder="Hectares"
            className="px-5 py-2 w-72 border border-gray-300 bg-[#fff9e7] text-black rounded"
          />
          <br />
          <br />

          <label htmlFor="state" className="text-[#53321c]">
            State:
          </label>
          <br />
          <input
            type="text"
            id="_state"
            name="_state"
            placeholder="Enter your State"
            value={details._state}
            onChange={handleChange}
            className="px-5 py-2 w-72 border border-gray-300  bg-[#fff9e7] text-black rounded"
          />
          <br />
          <br />

          <label className="text-[#53321c]">
            Country:
            <select
              name="_country"
              value={details._country}
              onChange={handleChange}
              className="px-5 py-2 w-72 flex border border-gray-300 bg-[#fff9e7] text-black rounded"
              placeholder="Select Your Country"
              required
            >
              <option key="" value=""></option>
              {country.map((country) => (
                <option key={country} value={country}>
                  {country}
                </option>
              ))}
            </select>
          </label>
          <br />

          {isLoading ? (
            <button
              type="submit"
              disabled={isLoading}
              className="px-10 py-2 mt-4 text-lg font-medium text-center text-white bg-[#b0d541] hover:bg-[#a6ca3b] transition duration-150 ease-out hover:ease-in rounded-md"
            >
              ...
            </button>
          ) : (
            <button
              type="submit"
              disabled={isLoading}
              className="px-10 py-2 mt-4 text-lg font-medium text-center text-white bg-[#b0d541] hover:bg-[#a6ca3b] transition duration-150 ease-out hover:ease-in rounded-md"
            >
              Submit
            </button>
          )}
        </form>
      </div>
      <Footer />
    </div>
  );
};

export default SignIn;
