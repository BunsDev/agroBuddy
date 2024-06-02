'use client'
import Link from "next/link";
import { Disclosure } from "@headlessui/react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import{ switchNetworkToAmoy , getUserAddress } from "../utils"
import {useState } from 'react';

const Navbar = () => {
  const [userAddress, setUserAddress] = useState(null);

  const handleGetStarted = async () => {
    await switchNetworkToAmoy();
    const address = await getUserAddress();
    setUserAddress(address);
  };

  const truncateAddress = (address) => {
    if (!address) return '';
    const halfLength = Math.ceil(address.length / 4);
    return `${address.substring(0, halfLength)}....`;
  };


  const navigation = [
    { label: 'Register', path: '/SignIn' },
    { label: 'Dashboard', path: '/dashboard' },
    { label: 'Claim', path: '/claim' },
    { label: 'Stake', path: '/staker' },
    { label: 'Items', path: '/toggle' },
  ];

  return (
    <div className="w-full absolute top-0 left-0 right-0">
      <nav className="container relative flex flex-wrap items-center justify-between p-8 mx-auto lg:justify-between xl:px-0">
        {/* Logo  */}
        <Disclosure>
          {({ open }) => (
            <>
              <div className="flex flex-wrap items-center justify-between w-full lg:w-auto">

                <Disclosure.Button
                  aria-label="Toggle Menu"
                  className="px-2 py-1 ml-auto text-gray-500 rounded-md lg:hidden hover:text-[#e8f4ec] focus:text-[#e8f4ec] focus:bg-[#e8f4ec] focus:outline-none dark:text-gray-300 dark:focus:bg-trueGray-700">
                  <svg
                    className="w-6 h-6 fill-current"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24">
                    {open ? (
                      <path
                        fillRule="evenodd"
                        clipRule="evenodd"
                        d="M18.278 16.864a1 1 0 0 1-1.414 1.414l-4.829-4.828-4.828 4.828a1 1 0 0 1-1.414-1.414l4.828-4.829-4.828-4.828a1 1 0 0 1 1.414-1.414l4.829 4.828 4.828-4.828a1 1 0 1 1 1.414 1.414l-4.828 4.829 4.828 4.828z"
                      />
                    ) : (
                      <path
                        fillRule="evenodd"
                        d="M4 5h16a1 1 0 0 1 0 2H4a1 1 0 1 1 0-2zm0 6h16a1 1 0 0 1 0 2H4a1 1 0 0 1 0-2zm0 6h16a1 1 0 0 1 0 2H4a1 1 0 1 1 0-2z"
                      />
                    )}
                  </svg>
                </Disclosure.Button>

                <Disclosure.Panel className="flex flex-wrap w-full my-5 lg:hidden">
                  <>
                    {navigation.map((item, index) => (
                      <Link key={index} href={item.path} className="w-full px-4 py-2 -ml-4 text-gray-500 rounded-md dark:text-gray-300 hover:text-[#e8f4ec] focus:text-[#e8f4ec] focus:bg-indigo-100 dark:focus:bg-gray-800 focus:outline-none">
                         {item.label}
                      </Link>
                    ))}
                  </>
                </Disclosure.Panel>
              </div>
            </>
          )}
        </Disclosure>

        {/* menu  */}
        <div className="hidden text-center lg:flex lg:justify-between lg:items-center">
          <ul className="items-center justify-end flex-1 pt-6 relative left-[11rem] -top-1 list-none lg:pt-0 lg:flex">
            {navigation.map((menu, index) => (
              <li className="mr-3 nav__item" key={index}>
                <Link href={menu.path} className="inline-block px-4 py-2 text-lg font-normal font-sans text-gray-800 hover:underline-offset-2 rounded-md dark:text-gray-200 hover:text-greean-600 focus:text-green-600 hover:text-[#17a34b] focus:bg-[#e8f4ec] focus:outline-none dark:focus:bg-gray-800">
                {menu.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        {/* <div className="hidden mr-3 space-x-4 lg:flex nav__item absolute  ">
          <Link href="/" className="px-6 py-2 text-white bg-indigo-600 rounded-md md:ml-5">
              Get Started
          </Link>
        </div> */}

<div className="hidden mr-3 space-x-4 lg:flex nav__item relative right-6">
          {userAddress ? (
            <div className="px-6 py-2 text-black bg-gray-100 rounded-md md:ml-5 shadow-2xl border border-black text-left z-50">
              {truncateAddress(userAddress)}
            </div>
          ) : (
            <button className="px-6 py-2 text-white bg-indigo-600 hover:bg-indigo-700 ease-in-out duration-500 rounded-md md:ml-5" onClick={handleGetStarted}>
              Get Started
            </button>
          )}
        </div>
      </nav>
    </div>
  );
}

export default Navbar;
