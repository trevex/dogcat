import { useState } from 'react';
import type { NextPage } from 'next'
import dynamic from "next/dynamic";
import Head from 'next/head'
import Image from 'next/image'

import cat1 from '../public/cat-body-01.png'
import cat2 from '../public/cat-body-02.png'
import cat3 from '../public/cat-body-03.png'
import cat4 from '../public/cat-body-04.png'
import dog1 from '../public/dog-body-01.png'
import dog2 from '../public/dog-body-02.png'
import dog3 from '../public/dog-body-03.png'
import dog4 from '../public/dog-body-04.png'


const Game = dynamic(() => import("../components/Game"), {
    ssr: false,
});


const Home: NextPage = () => {
    const [score, setScore] = useState(0);

    return (
        <div>
            <Head>
                <title>DogCat</title>
                <meta name="description" content="Basically two-ended snake" />
                <link rel="icon" href="/favicon.ico" />
            </Head>
            <div className="flex flex-col items-center h-screen bg-stone-200">
                <div className="grid grid-flow-row auto-rows-max">
                    <div className="flex content-between">
                        <div className="-mb-2">
                            <Image alt="Cat 1" src={cat1} width={64} height={64} />
                            <Image alt="Cat 2" src={cat2} width={64} height={64} />
                            <Image alt="Cat 3" src={cat3} width={64} height={64} />
                            <Image alt="Cat 4" src={cat4} width={64} height={64} />
                        </div>
                        <div className="m-auto">
                            <p className="font-sans text-2xl text-center">Score: {score}</p>
                        </div>
                        <div className="-mb-2">
                            <Image alt="Dog 1" src={dog1} width={64} height={64} />
                            <Image alt="Dog 2" src={dog2} width={64} height={64} />
                            <Image alt="Dog 3" src={dog3} width={64} height={64} />
                            <Image alt="Dog 4" src={dog4} width={64} height={64} />
                        </div>
                    </div>
                    <div className="border-solid border-8 border-black rounded-lg">
                        <Game size={800} cells={25} onScoreChange={setScore} />
                    </div>
                </div>

            </div>
        </div>
    )
}

export default Home
